#!/bin/bash
# copy_and_resize_images.sh
# Batch-resizes PNG/JPG screenshots for Journey Markdown reports while archiving full-resolution originals.

set -e

SOURCE_DIR="$1"
DEST_DIR="$2"
WIDTH="${3:-420}" # Default to 420px width so UI text, badges, and edge clipping remain crisp and legible

if [ -z "$SOURCE_DIR" ] || [ -z "$DEST_DIR" ]; then
  echo "Error: Source and destination directories are required."
  echo "Usage: $0 <source_directory> <destination_directory> [width]"
  exit 1
fi

mkdir -p "$DEST_DIR"

shopt -s nullglob
img_files=("$SOURCE_DIR"/*.png "$SOURCE_DIR"/*.jpg "$SOURCE_DIR"/*.jpeg)

if [ ${#img_files[@]} -eq 0 ]; then
  echo "No .png/.jpg files found in $SOURCE_DIR"
  exit 0
fi

# Preserve full-resolution originals when resizing in-place so reviewers can inspect full detail if needed
if [ "$SOURCE_DIR" = "$DEST_DIR" ]; then
  mkdir -p "$DEST_DIR/full"
fi

echo "Processing and resizing ${#img_files[@]} images to max ${WIDTH}px wide..."

for f in "${img_files[@]}"; do
  filename=$(basename "$f")
  stem="${filename%.*}"
  out_png="$DEST_DIR/${stem}.png"

  if [ "$SOURCE_DIR" = "$DEST_DIR" ] && [ ! -f "$DEST_DIR/full/$filename" ]; then
    cp -p "$f" "$DEST_DIR/full/$filename"
  fi

  if command -v sips >/dev/null 2>&1; then
    sips -s format png --resampleWidth "$WIDTH" "$f" --out "$out_png" >/dev/null
  elif command -v magick >/dev/null 2>&1; then
    magick "$f" -resize "${WIDTH}x" "$out_png"
  else
    cp -p "$f" "$out_png"
  fi

  if [ "$f" != "$out_png" ] && [ "$SOURCE_DIR" = "$DEST_DIR" ]; then
    rm -f "$f"
  fi
  echo "  -> Ready: $(basename "$out_png")"
done

echo "Done!"
