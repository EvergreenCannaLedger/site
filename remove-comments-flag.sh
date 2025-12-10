#!/bin/bash

# Directory to scan
POSTS_DIR="posts"

# Loop through all .qmd files
find "$POSTS_DIR" -type f -name "*.qmd" | while read -r file; do
    echo "Processing $file..."

    awk '
    BEGIN { in_yaml=0 }
    # Toggle in_yaml when encountering ---
    /^---\s*$/ {
        if (in_yaml == 0) {
            in_yaml = 1
        } else {
            in_yaml = 0
        }
        print
        next
    }

    # While in YAML header, skip the comments: true line
    in_yaml == 1 && /^\s*comments:\s*true\s*$/ {
        next
    }

    { print }
    ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"

done

echo "✅ Done removing 'comments: true' from all .qmd files in '$POSTS_DIR'"
