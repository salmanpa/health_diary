#!/bin/sh
set -eu

project_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

"$project_dir/scripts/init_db.sh"
python3 "$project_dir/scripts/generate_dashboard.py" --compact
"$project_dir/scripts/build_dashboard_ui.sh"

echo "Dashboard snapshot and UI are ready (latest source date printed above)."
