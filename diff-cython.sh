#!/bin/bash

BASE_DIR="/home/sj/monza/source/cython"
TARGET_DIR="/home/sj/raimadb-python/src/rdm"

echo "=== Starting Cython/PXD diff between repos ==="
echo "Base (recursive): $BASE_DIR"
echo "Target (flat):    $TARGET_DIR"
echo

# Use find with -print0 + read -d '' to handle filenames with spaces/newlines safely
find "$BASE_DIR" -type f \( -name "*.pyx" -o -name "*.pxd" \) -print0 |
while IFS= read -r -d '' src_file; do
    base_name=$(basename "$src_file")
    tgt_file="$TARGET_DIR/$base_name"

    if [ -f "$tgt_file" ]; then
        echo "=== DIFF: $base_name ==="
        echo "Left (Monza):  $src_file"
        echo "Right (Raima): $tgt_file"
        echo

        # Use git diff --no-index so you get the familiar git diff output
        # (colors, unified diff, etc.) even though the files are in separate repos.
        git diff --color=always --no-index -- "$src_file" "$tgt_file" || true
        echo "────────────────────────────────────────"
    else
        echo "No match in target for: $base_name (skipped)"
    fi
done

echo
echo "=== Diff complete ==="
