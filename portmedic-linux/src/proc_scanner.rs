//! Scans `/proc` for listening sockets and resolves them to owning processes.
//!
//! Deliberately avoids shelling out to `lsof`/`ss`/`netstat`: those aren't
//! guaranteed to be installed on every distro, and reading `/proc` directly
//! keeps the same "no subprocess, no shell interpolation" trust boundary
//! used by the macOS `CommandRunner`/`LsofOutputParser` pair.
//!
use crate::model::PortProcessInfo;
use crate::model::TransportProtocol;
use std::collections::HashMap;
use std::fs;
use std::io;
use std::os::unix::fs::MetadataExt;
use std::path::Path;

pub fn scan() -> std::io::Result<Vec<PortProcessInfo>> {
    let sockets = [
        ("/proc/net/tcp", TransportProtocol::Tcp),
        ("/proc/net/tcp6", TransportProtocol::Tcp),
        ("/proc/net/udp", TransportProtocol::Udp),
        ("/proc/net/udp6", TransportProtocol::Udp),
    ]
    .into_iter()
    .map(|(path, protocol)| read_socket_table(path, protocol))
    .collect::<io::Result<Vec<_>>>()?
    .into_iter()
    .flatten()
    .collect::<Vec<_>>();

    let owners = socket_owners()?;
    let mut processes = Vec::new();

    for socket in sockets {
        let Some(pids) = owners.get(&socket.inode) else {
            continue;
        };
        for pid in pids {
            processes.push(PortProcessInfo {
                pid: *pid,
                port: socket.port,
                protocol: socket.protocol,
                process_name: process_name(*pid),
                user: process_user(*pid),
            });
        }
    }

    processes.sort_by_key(|process| (process.port, process.pid));
    processes.dedup();
    Ok(processes)
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
struct SocketEntry {
    port: u16,
    protocol: TransportProtocol,
    inode: u64,
}

fn read_socket_table(path: &str, protocol: TransportProtocol) -> io::Result<Vec<SocketEntry>> {
    let contents = fs::read_to_string(path)?;
    Ok(parse_socket_table(&contents, protocol))
}

fn parse_socket_table(contents: &str, protocol: TransportProtocol) -> Vec<SocketEntry> {
    contents
        .lines()
        .skip(1)
        .filter_map(|line| {
            let fields: Vec<_> = line.split_whitespace().collect();
            let state = fields.get(3)?;
            if protocol == TransportProtocol::Tcp && *state != "0A" {
                return None;
            }

            let port = u16::from_str_radix(fields.get(1)?.rsplit_once(':')?.1, 16).ok()?;
            let inode = fields.get(9)?.parse::<u64>().ok()?;
            Some(SocketEntry {
                port,
                protocol,
                inode,
            })
        })
        .collect()
}

fn socket_owners() -> io::Result<HashMap<u64, Vec<i32>>> {
    let mut owners: HashMap<u64, Vec<i32>> = HashMap::new();
    for entry in fs::read_dir("/proc")? {
        let entry = entry?;
        let Some(pid) = entry
            .file_name()
            .to_str()
            .and_then(|name| name.parse().ok())
        else {
            continue;
        };
        let fd_path = entry.path().join("fd");
        let Ok(fds) = fs::read_dir(fd_path) else {
            continue;
        };
        for fd in fds.flatten() {
            let Ok(target) = fs::read_link(fd.path()) else {
                continue;
            };
            let Some(inode) = socket_inode(&target) else {
                continue;
            };
            owners.entry(inode).or_default().push(pid);
        }
    }
    Ok(owners)
}

fn socket_inode(path: &Path) -> Option<u64> {
    let value = path.to_str()?.strip_prefix("socket:[")?.strip_suffix(']')?;
    value.parse().ok()
}

fn process_name(pid: i32) -> String {
    fs::read_to_string(format!("/proc/{pid}/comm"))
        .map(|name| name.trim().to_owned())
        .unwrap_or_else(|_| "unknown".to_owned())
}

fn process_user(pid: i32) -> String {
    fs::metadata(format!("/proc/{pid}"))
        .map(|metadata| metadata.uid().to_string())
        .unwrap_or_else(|_| "unknown".to_owned())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_listening_tcp_socket() {
        let table = "  sl local_address rem_address st tx_queue rx_queue tr tm->when retrnsmt   uid  timeout inode\n   0: 0100007F:1F90 00000000:0000 0A 00000000:00000000 00:00000000 00000000   1000        0 4242 1 0000000000000000 100 0 0 10 0\n";

        assert_eq!(
            parse_socket_table(table, TransportProtocol::Tcp),
            vec![SocketEntry {
                port: 8080,
                protocol: TransportProtocol::Tcp,
                inode: 4242,
            }]
        );
    }

    #[test]
    fn ignores_non_listening_tcp_socket() {
        let table = "header\n0: 0100007F:0016 00000000:0000 01 0 0 0 0 0 123 0 9000\n";

        assert!(parse_socket_table(table, TransportProtocol::Tcp).is_empty());
    }

    #[test]
    fn parses_bound_udp_socket() {
        let table =
            "header\n0: 0100007F:15B3 00000000:0000 07 00000000 00:00000000 00000000 123 0 9001\n";

        assert_eq!(
            parse_socket_table(table, TransportProtocol::Udp),
            vec![SocketEntry {
                port: 5555,
                protocol: TransportProtocol::Udp,
                inode: 9001,
            }]
        );
    }
}
