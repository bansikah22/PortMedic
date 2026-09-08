//! Sends POSIX signals to terminate processes, mirroring the PID-safety
//! rules already reviewed and tested in `SignalProcessTerminator.swift`:
//! reject non-positive PIDs, PID 1 (init), and the app's own PID.

use nix::sys::signal::{self, Signal};
use nix::unistd::Pid;

#[derive(Debug, thiserror::Error)]
pub enum ProcessTerminationError {
    #[error("refusing to terminate process {0}: not a valid, safe target")]
    UnsafeTarget(i32),
    #[error("failed to signal process {0}: {1}")]
    SignalFailed(i32, nix::Error),
}

/// Mirrors `SignalProcessTerminator.isSafeTarget(_:)` on macOS.
pub fn is_safe_target(pid: i32) -> bool {
    pid > 0 && pid != 1 && pid != std::process::id() as i32
}

pub fn terminate(pid: i32) -> Result<(), ProcessTerminationError> {
    send(pid, Signal::SIGTERM)
}

pub fn force_terminate(pid: i32) -> Result<(), ProcessTerminationError> {
    send(pid, Signal::SIGKILL)
}

fn send(pid: i32, sig: Signal) -> Result<(), ProcessTerminationError> {
    if !is_safe_target(pid) {
        return Err(ProcessTerminationError::UnsafeTarget(pid));
    }
    signal::kill(Pid::from_raw(pid), sig).map_err(|e| ProcessTerminationError::SignalFailed(pid, e))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn rejects_pid_zero() {
        assert!(!is_safe_target(0));
    }

    #[test]
    fn rejects_init() {
        assert!(!is_safe_target(1));
    }

    #[test]
    fn rejects_negative_pids() {
        assert!(!is_safe_target(-5));
    }

    #[test]
    fn rejects_own_process() {
        assert!(!is_safe_target(std::process::id() as i32));
    }

    #[test]
    fn allows_ordinary_pid() {
        assert!(is_safe_target(4512));
    }
}
