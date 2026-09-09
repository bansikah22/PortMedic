//! Data model shared across the scanner, process control, and UI layers.
//! Mirrors `PortProcessInfo` from the macOS Swift implementation.

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct PortProcessInfo {
    pub pid: i32,
    pub port: u16,
    pub protocol: TransportProtocol,
    pub process_name: String,
    pub user: String,
    pub exe_path: Option<String>,
    pub working_dir: Option<String>,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum TransportProtocol {
    Tcp,
    Udp,
}
