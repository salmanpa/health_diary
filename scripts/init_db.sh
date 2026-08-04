#!/bin/sh
set -eu

project_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
database_path="$project_dir/data/health_diary.sqlite3"

mkdir -p "$project_dir/data"
sqlite3 "$database_path" < "$project_dir/db/schema.sql"
sqlite3 "$database_path" < "$project_dir/db/seed.sql"

echo "Health diary database initialized: $database_path"
