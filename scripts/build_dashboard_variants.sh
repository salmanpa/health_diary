#!/bin/sh
set -eu

project_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
stage_dir=$(mktemp -d "${TMPDIR:-/tmp}/health-diary-dashboard.XXXXXX")
trap 'rm -rf "$stage_dir"' EXIT HUP INT TERM

build_variant() {
    mode=$1
    target=$2
    variant_dir="$stage_dir/$mode"
    vite build \
        --config "$project_dir/dashboard-src/vite.config.ts" \
        --mode "$mode" \
        --outDir "$variant_dir"
    cp "$variant_dir/index.html" "$project_dir/dashboard/$target"
}

mkdir -p "$project_dir/dashboard"
build_variant variant-1 index.html
build_variant variant-2 02-night-lab.html
build_variant variant-3 03-macro-bento.html
build_variant variant-4 04-recovery-report.html
build_variant variant-5 05-data-console.html

echo "Built 5 self-contained dashboard variants in $project_dir/dashboard"
