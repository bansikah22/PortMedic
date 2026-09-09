//! Copy-to-clipboard and open-in-browser. Mirrors `ProcessQuickActionPerforming`;
//! clipboard access itself is handled by `iced::clipboard` at the call site.
use std::path::PathBuf;
use std::process::Command;

/// Resolves an absolute executable path via `PATH`, the same "absolute path,
/// argument array, never a shell string" rule `CommandRunner` uses on macOS.
fn resolve_executable(name: &str) -> Option<PathBuf> {
    let path_var = std::env::var_os("PATH")?;
    std::env::split_paths(&path_var)
        .map(|dir| dir.join(name))
        .find(|candidate| candidate.is_file())
}

pub fn open_in_browser(url: &str) -> bool {
    let Some(executable) = resolve_executable("xdg-open") else {
        return false;
    };
    Command::new(executable).arg(url).spawn().is_ok()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn resolves_a_known_executable_on_path() {
        assert!(resolve_executable("sh").is_some());
    }

    #[test]
    fn returns_none_for_an_unknown_executable() {
        assert!(resolve_executable("definitely-not-a-real-binary-xyz").is_none());
    }
}
