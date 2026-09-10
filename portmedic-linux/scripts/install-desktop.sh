#!/usr/bin/env sh
set -eu

project_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
data_dir=${XDG_DATA_HOME:-"$HOME/.local/share"}
applications_dir="$data_dir/applications"
icons_dir="$data_dir/icons/hicolor/256x256/apps"
desktop_file="$applications_dir/com.portmedic.PortMedic.desktop"

mkdir -p "$applications_dir" "$icons_dir"
cp "$project_dir/assets/portmedic.png" "$icons_dir/portmedic.png"

sed "s#^Exec=.*#Exec=$project_dir/target/debug/portmedic-linux#" \
    "$project_dir/com.portmedic.PortMedic.desktop" > "$desktop_file"

update-desktop-database "$applications_dir" 2>/dev/null || true

printf 'Installed PortMedic desktop entry at %s\n' "$desktop_file"