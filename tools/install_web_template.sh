#!/usr/bin/env bash
set -euo pipefail

# Godot's Web exporter is a separate download from the editor binary.
version="4.6.3"
version_dir="4.6.3.stable"
archive_url="https://github.com/godotengine/godot/releases/download/${version}-stable/Godot_v${version}-stable_export_templates.tpz"
expected_sha256="3fbe2c0e2dec9d537ab9ec97bcf8da91dcf23357fc51f67092dd068d839290a8"
data_root="${XDG_DATA_HOME:-${HOME}/.local/share}"
template_dir="${data_root}/godot/export_templates/${version_dir}"

if [[ -f "${template_dir}/web_nothreads_debug.zip" && -f "${template_dir}/web_nothreads_release.zip" ]]; then
  echo "Godot Web export templates are already installed."
  exit 0
fi

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT
archive="${tmp_dir}/export_templates.tpz"
mkdir -p "$template_dir"
curl --fail --location --retry 2 --retry-delay 2 --output "$archive" "$archive_url"
printf '%s  %s\n' "$expected_sha256" "$archive" | sha256sum --check --status
unzip -p "$archive" templates/web_nothreads_debug.zip > "${template_dir}/web_nothreads_debug.zip"
unzip -p "$archive" templates/web_nothreads_release.zip > "${template_dir}/web_nothreads_release.zip"
echo "Godot Web export templates installed in ${template_dir}."
