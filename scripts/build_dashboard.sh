#!/bin/sh
set -eu

project_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

"$project_dir/scripts/init_db.sh"
python3 "$project_dir/scripts/generate_dashboard.py"

echo "Dashboard is ready: $project_dir/dashboard/index.html"
