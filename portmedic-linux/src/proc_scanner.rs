//! Scans `/proc` for listening sockets and resolves them to owning processes.
//!
//! Deliberately avoids shelling out to `lsof`/`ss`/`netstat`: those aren't
//! guaranteed to be installed on every distro, and reading `/proc` directly
//! keeps the same "no subprocess, no shell interpolation" trust boundary
//! used by the macOS `CommandRunner`/`LsofOutputParser` pair.
//!
//! Implementation is intentionally left as a stub pending review of the
//! project skeleton; see the module doc in `main.rs`.

use crate::model::PortProcessInfo;

pub fn scan() -> std::io::Result<Vec<PortProcessInfo>> {
    // TODO: parse /proc/net/{tcp,tcp6,udp,udp6}, resolve socket inodes to
    // PIDs via /proc/<pid>/fd/*, then read /proc/<pid>/comm for the name.
    Ok(Vec::new())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn scan_returns_ok_before_implementation() {
        assert!(scan().is_ok());
    }
}
