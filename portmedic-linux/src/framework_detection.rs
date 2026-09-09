use crate::model::PortProcessInfo;

pub fn detect(port: &PortProcessInfo) -> Option<&'static str> {
    match port.port {
        5173 => Some("Vite"),
        5432 => Some("PostgreSQL"),
        3306 => Some("MySQL"),
        6379 => Some("Redis"),
        27017 => Some("MongoDB"),
        _ => {
            let name = port.process_name.to_lowercase();
            if name.contains("node") {
                Some(if port.port == 3000 {
                    "Next.js"
                } else {
                    "Node.js"
                })
            } else if name.contains("java") {
                Some("Spring Boot")
            } else if name.contains("python") {
                Some("Python")
            } else if name.contains("docker") {
                Some("Docker")
            } else if name.contains("rust") {
                Some("Rust")
            } else if name.contains("go") {
                Some("Go")
            } else {
                None
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::model::TransportProtocol;

    fn process(port: u16, process_name: &str) -> PortProcessInfo {
        PortProcessInfo {
            pid: 42,
            port,
            protocol: TransportProtocol::Tcp,
            process_name: process_name.to_owned(),
            user: "1000".to_owned(),
        }
    }

    #[test]
    fn detects_port_and_process_hints() {
        assert_eq!(detect(&process(5173, "unknown")), Some("Vite"));
        assert_eq!(detect(&process(3000, "node")), Some("Next.js"));
        assert_eq!(detect(&process(8080, "java")), Some("Spring Boot"));
        assert_eq!(detect(&process(9999, "unknown")), None);
    }
}
