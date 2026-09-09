# PortMedic for Linux (experimental)

A Rust port of PortMedic's core idea: find and terminate the process
occupying a development port, without leaving your editor.

## Status

**Scaffold only.** This crate currently builds a placeholder window; the
`/proc` scanner and process termination modules contain stubs and unit tests
for the logic that is safe to write without a Linux machine to validate
against (PID-safety rules). Real `/proc/net/tcp` parsing, PID resolution,
and the full iced UI are implemented in follow-up changes.

## Why a Rust rewrite instead of reusing the Swift code

PortMedic's macOS build relies on `lsof`, AppKit, Carbon, and SwiftUI — none
of which exist on Linux. The UX and safety decisions (graceful terminate
before Force Kill, PID-safety checks, watched ports, quick actions) carry
over; the implementation does not.

## Design decisions

- **UI**: [iced](https://iced.rs), for a consistent look across Linux
  desktop environments and an Elm-architecture that maps directly onto the
  existing MVVM/state-reducer pattern used on macOS.
- **Port scanning**: direct `/proc` parsing (`/proc/net/tcp[6]`,
  `/proc/net/udp[6]`, `/proc/<pid>/fd/*`, `/proc/<pid>/comm`) instead of
  shelling out to `lsof`/`ss`/`netstat`, which aren't guaranteed to be
  installed on every distro. No shell interpolation, no subprocess trust
  surface — same principle as the macOS `CommandRunner`.
- **Process termination**: the `nix` crate's `kill()` binding, sending
  `SIGTERM` first and `SIGKILL` only after explicit confirmation if the
  process is still holding the port — identical flow to the macOS app.
- **Tray**: `tray-icon`, as the equivalent of the macOS `MenuBarExtra`.

## Requirements

- Rust (stable) via [rustup](https://rustup.rs)

## Testing on your Linux machine

This crate only builds on Linux — `tray-icon` and iced's windowing backend
pull in X11/Wayland system libraries that don't exist on macOS, so it
cannot be built or run from the same machine used for the Swift app.

1. Install system dependencies (Debian/Ubuntu example; adjust for your distro):

   ```bash
   sudo apt update
   sudo apt install -y build-essential pkg-config libssl-dev \
       libgtk-3-dev libglib2.0-dev libxdo-dev libappindicator3-dev \
       libxkbcommon-dev libx11-dev libxcb1-dev libwayland-dev
   ```

2. Install Rust if you haven't already:

   ```bash
   curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
   ```

3. Clone the repo and check out this branch:

   ```bash
   git clone https://github.com/bansikah22/PortMedic.git
   cd PortMedic
   git checkout feature/linux-port
   ```

   If you already have the repo cloned elsewhere (e.g. from working on the
   macOS side), just `git fetch origin` then `git checkout feature/linux-port`.

4. Build, lint, and test from inside `portmedic-linux/`:

   ```bash
   cd portmedic-linux
   cargo build
   cargo fmt -- --check
   cargo clippy --all-targets -- -D warnings
   cargo test
   ```

5. Run it:

   ```bash
   cargo run
   ```

Pushing to `feature/linux-port` also triggers `.github/workflows/ci-linux.yml`
on GitHub's `ubuntu-latest` runner, so CI validates every change even
between local test runs on your machine.

## Building

```bash
cd portmedic-linux
cargo build
```

## Roadmap

See the parent repository's `docs/future-improvements` for the full feature
list. Linux v1 target: port table + search, framework detection, graceful
terminate + Force Kill, Watched Ports, quick actions (copy PID, copy
localhost URL, open in browser), tray icon. Deferred: global shortcut
(desktop-environment-specific, no uniform API), launch-at-login via XDG
autostart, packaging as an AppImage first.

## Architecture

See [ARCHITECTURE.md](ARCHITECTURE.md) for module layout, the `/proc`
scanning approach, process-termination safety rules, and testing strategy.
