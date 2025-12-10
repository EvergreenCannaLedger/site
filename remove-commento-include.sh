#!/bin/bash

POSTS_DIR="posts"

echo "🧼 Removing '{{< include _includes/commento.html >}}' from .qmd files in $POSTS_DIR..."

find "$POSTS_DIR" -type f -name "*.qmd" | while read -r file; do
  echo "→ Cleaning: $file"
  
  # Write to a temp file, then overwrite the original
  awk '!/{{< *include *_includes\/commento\.html *>}}/' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
done

echo "✅ All files processed. Commento includes removed."
