#!/bin/sh
set -eu

project_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
database_path="$project_dir/data/health_diary.sqlite3"

mkdir -p "$project_dir/data"

if sqlite3 "$database_path" \
    "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = 'chess_sessions';" \
    | grep -q 1 \
    && ! sqlite3 "$database_path" \
        "SELECT 1 FROM pragma_table_info('chess_sessions') WHERE name = 'draws';" \
        | grep -q 1; then
    sqlite3 "$database_path" \
        "ALTER TABLE chess_sessions ADD COLUMN draws INTEGER NOT NULL DEFAULT 0 CHECK (draws >= 0 AND wins + draws <= games_played);"
fi

sqlite3 "$database_path" < "$project_dir/db/schema.sql"
sqlite3 "$database_path" < "$project_dir/db/seed.sql"

echo "Health diary database initialized: $database_path"
