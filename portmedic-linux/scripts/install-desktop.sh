#!/usr/bin/env sh
set -eu

project_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
data_dir=${XDG_DATA_HOME:-"$HOME/.local/share"}
applications_dir="$data_dir/applications"
icons_dir="$data_dir/icons/hicolor/256x256/apps"
desktop_file="$applications_dir/com.portmedic.PortMedic.desktop"
icon_source="$project_dir/assets/portmedic.png"
desktop_source="$project_dir/com.portmedic.PortMedic.desktop"
executable="$project_dir/target/debug/portmedic-linux"

require_file() {
    if [ ! -f "$1" ]; then
        printf 'Error: required file not found: %s\n' "$1" >&2
        exit 1
    fi
}

require_executable() {
    if [ ! -x "$1" ]; then
        printf 'Error: executable not found or not executable: %s\n' "$1" >&2
        exit 1
    fi
}

require_file "$icon_source"
require_file "$desktop_source"
require_executable "$executable"

mkdir -p "$applications_dir" "$icons_dir"
cp "$icon_source" "$icons_dir/portmedic.png"

sed "s#^Exec=.*#Exec=$project_dir/target/debug/portmedic-linux#" \
    "$desktop_source" > "$desktop_file"

update-desktop-database "$applications_dir" 2>/dev/null || true

printf 'Installed PortMedic desktop entry at %s\n' "$desktop_file"