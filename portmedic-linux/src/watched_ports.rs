use std::fs;
use std::io;
use std::path::PathBuf;

use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct WatchedPort {
    pub port: u16,
}

fn storage_path() -> PathBuf {
    std::env::var_os("XDG_CONFIG_HOME")
        .map(PathBuf::from)
        .unwrap_or_else(|| {
            std::env::var_os("HOME")
                .map(|home| PathBuf::from(home).join(".config"))
                .unwrap_or_else(|| PathBuf::from("."))
        })
        .join("portmedic")
        .join("watched-ports.json")
}

pub fn load() -> io::Result<Vec<WatchedPort>> {
    let path = storage_path();
    if !path.exists() {
        return Ok(Vec::new());
    }
    let data = fs::read(path)?;
    let mut ports: Vec<WatchedPort> = serde_json::from_slice(&data).map_err(io::Error::other)?;
    ports.retain(|watched| watched.port > 0);
    ports.sort_by_key(|watched| watched.port);
    ports.dedup_by_key(|watched| watched.port);
    Ok(ports)
}

pub fn save(ports: &[WatchedPort]) -> io::Result<()> {
    let path = storage_path();
    if let Some(parent) = path.parent() {
        fs::create_dir_all(parent)?;
    }
    let data = serde_json::to_vec_pretty(ports).map_err(io::Error::other)?;
    fs::write(path, data)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn watched_ports_are_ordered_and_deduplicated() {
        let mut ports = vec![
            WatchedPort { port: 8080 },
            WatchedPort { port: 3000 },
            WatchedPort { port: 8080 },
            WatchedPort { port: 0 },
        ];
        ports.retain(|watched| watched.port > 0);
        ports.sort_by_key(|watched| watched.port);
        ports.dedup_by_key(|watched| watched.port);

        assert_eq!(
            ports,
            vec![WatchedPort { port: 3000 }, WatchedPort { port: 8080 }]
        );
    }
}
