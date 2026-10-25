#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_dir"
mkdir -p build/web
godot4 --headless --path . --export-release Web build/web/index.html
echo "Web preview generated at $project_dir/build/web/index.html"
