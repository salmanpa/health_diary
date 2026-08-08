#!/bin/sh
set -eu

project_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
database_path="$project_dir/data/health_diary.sqlite3"
temporary_database="$project_dir/data/.health_diary.$$.sqlite3"

cleanup() {
    rm -f "$temporary_database"
}

trap cleanup EXIT HUP INT TERM

mkdir -p "$project_dir/data"
sqlite3 "$temporary_database" < "$project_dir/db/schema.sql"
sqlite3 "$temporary_database" < "$project_dir/db/seed.sql"
python3 "$project_dir/scripts/import_events.py" \
    --database "$temporary_database" \
    --events-dir "$project_dir/db/events"
sqlite3 "$temporary_database" "PRAGMA optimize; PRAGMA integrity_check;"

mv "$temporary_database" "$database_path"
trap - EXIT HUP INT TERM

echo "Health diary database initialized: $database_path"
