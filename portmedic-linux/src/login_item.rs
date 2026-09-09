//! Launch-at-login via an XDG autostart entry. Mirrors
//! `SMAppServiceLoginItemManager`'s idempotent register/unregister semantics,
//! swapped for the Linux desktop-integration equivalent of `SMAppService`.
use std::fs;
use std::io;
use std::path::PathBuf;

fn autostart_dir() -> PathBuf {
    std::env::var_os("XDG_CONFIG_HOME")
        .map(PathBuf::from)
        .unwrap_or_else(|| {
            std::env::var_os("HOME")
                .map(|home| PathBuf::from(home).join(".config"))
                .unwrap_or_else(|| PathBuf::from("."))
        })
        .join("autostart")
}

fn desktop_entry_path() -> PathBuf {
    autostart_dir().join("com.portmedic.PortMedic.desktop")
}

pub fn is_enabled() -> bool {
    desktop_entry_path().exists()
}

pub fn set_enabled(enabled: bool) -> io::Result<()> {
    let path = desktop_entry_path();
    if enabled {
        if path.exists() {
            return Ok(());
        }
        let exe = std::env::current_exe()?;
        let entry = format!(
            "[Desktop Entry]\nType=Application\nName=PortMedic\nComment=Find and free local development ports\nExec={}\nTerminal=false\nX-GNOME-Autostart-enabled=true\n",
            exe.display()
        );
        if let Some(parent) = path.parent() {
            fs::create_dir_all(parent)?;
        }
        fs::write(path, entry)
    } else if path.exists() {
        fs::remove_file(path)
    } else {
        Ok(())
    }
}
