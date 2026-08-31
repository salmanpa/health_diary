#!/bin/sh
set -eu

project_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

run_pnpm() {
    if command -v pnpm >/dev/null 2>&1; then
        pnpm "$@"
        return
    fi

    task_cache_root=$(python3 -c 'from pathlib import Path; print(Path.home() / ".cache")')
    task_node_dir="$task_cache_root/codex-runtimes/codex-primary-runtime/dependencies/node/bin"
    task_node="$task_node_dir/node"
    task_pnpm="$task_cache_root/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/pnpm/bin/pnpm.cjs"
    if [ -x "$task_node" ] && [ -f "$task_pnpm" ]; then
        PATH="$task_node_dir:/usr/bin:/bin" "$task_node" "$task_pnpm" "$@"
        return
    fi

    echo "pnpm is required. Install Node.js and pnpm, then run: pnpm install" >&2
    exit 1
}

cd "$project_dir"
run_pnpm run dashboard:build
perl -pi -e 's/[ \t]+$//' "$project_dir/dashboard/index.html"
echo "Dashboard UI is ready: $project_dir/dashboard/index.html"
