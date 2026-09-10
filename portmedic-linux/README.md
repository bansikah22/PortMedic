# PortMedic for Linux (experimental)

A Rust port of PortMedic's core idea: find and terminate the process
occupying a development port, without leaving your editor.

## Status

**Experimental.** This crate provides the Linux dashboard, process scanning,
process controls, watched ports, quick actions, settings, global shortcut,
and system tray integration. Linux releases are distributed as portable
`tar.gz` archives; distro-native packages are not provided yet.

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

3. Clone the repo and check out the desired branch or tag:

   ```bash
   git clone https://github.com/bansikah22/PortMedic.git
   cd PortMedic
   git checkout main
   ```

   If you already have the repo cloned elsewhere, run `git fetch origin` and
   check out the desired branch or release tag.

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

6. Register the desktop launcher and application icon for the current user:

   ```bash
   ./scripts/install-desktop.sh
   ```

The installer registers `com.portmedic.PortMedic.desktop`, installs the
PortMedic PNG in the user's hicolor icon theme, and points the launcher at
the debug binary. Re-run it after rebuilding if the executable path changes.
The tray's **Show PortMedic** action restores and focuses the existing window;
it does not start a second instance.

## Installing a Linux release

Download `PortMedic-linux-X.Y.Z.tar.gz` and its `.sha256` checksum from the
[GitHub Releases page](https://github.com/bansikah22/PortMedic/releases). Verify
and extract the archive, then run the installer:

```bash
sha256sum --check PortMedic-linux-X.Y.Z.tar.gz.sha256
tar -xzf PortMedic-linux-X.Y.Z.tar.gz
cd PortMedic-linux-X.Y.Z
./install.sh
```

The installer validates the platform, bundled binary, and required shared
libraries, then copies the desktop entry and icon into the current user's XDG
data directories. It does not require `sudo`. Launch PortMedic from the
applications menu or run `./portmedic-linux` directly.

The release is built on Ubuntu and requires the system libraries used by the
GTK/tray and iced window backends. On Debian or Ubuntu, install:

```bash
sudo apt install libgtk-3-0 libxkbcommon0 libx11-6 libxcb1 libwayland-client0 libxdo3
```

Library package names vary by distribution. The source-build dependency list
below includes the development packages needed to compile the application.

For a source checkout, build first with `cargo build --release`, then run
`./install.sh` from `portmedic-linux/`. The script automatically finds the
release or debug binary.

Pushes and pull requests that change `portmedic-linux/` trigger
`.github/workflows/ci-linux.yml` on GitHub's `ubuntu-latest` runner. Version
`linux-vX.Y.Z` tags trigger the Linux release workflow, which publishes the
archive and checksum to the GitHub release.

## Building from source

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
