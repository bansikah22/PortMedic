#!/usr/bin/env sh
set -eu

package_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
binary="$package_dir/portmedic-linux"

if [ "$(uname -s)" != "Linux" ]; then
    printf 'Error: PortMedic Linux can only be installed on Linux.\n' >&2
    exit 1
fi

if [ ! -x "$binary" ]; then
    for candidate in \
        "$package_dir/target/release/portmedic-linux" \
        "$package_dir/target/debug/portmedic-linux"; do
        if [ -x "$candidate" ]; then
            binary="$candidate"
            break
        fi
    done
fi

if [ ! -x "$binary" ]; then
    printf 'Error: PortMedic binary not found. Build it with `cargo build --release` first.\n' >&2
    exit 1
fi

if command -v ldd >/dev/null 2>&1; then
    missing_libraries=$(ldd "$binary" 2>/dev/null | sed -n '/not found/p' || true)
    if [ -n "$missing_libraries" ]; then
        printf 'Error: required system libraries are missing:\n%s\n' "$missing_libraries" >&2
        printf 'See portmedic-linux/README.md for Debian/Ubuntu dependency names.\n' >&2
        exit 1
    fi
fi

"$package_dir/scripts/install-desktop.sh" "$binary"

printf '\nPortMedic is installed for the current user.\n'
printf 'Launch it from your applications menu or run: %s\n' "$binary"
