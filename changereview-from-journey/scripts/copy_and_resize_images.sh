#!/bin/bash
# copy_and_resize_images.sh

SOURCE_DIR="$1"
DEST_DIR="$2"
WIDTH="${3:-200}" # Default to 200px width if a 3rd argument isn't provided

# Validation
if [ -z "$SOURCE_DIR" ] || [ -z "$DEST_DIR" ]; then
  echo "Error: Source and destination directories are required."
  echo "Usage: $0 <source_directory> <destination_directory> [width]"
  exit 1
fi

# Ensure destination directory exists
mkdir -p "$DEST_DIR"

# Enable nullglob so the array is empty if no matches are found
shopt -s nullglob
png_files=("$SOURCE_DIR"/*.png)

if [ ${#png_files[@]} -eq 0 ]; then
  echo "No .png files found in $SOURCE_DIR"
  exit 0
fi

echo "Copying and resizing ${#png_files[@]} images to $WIDTH pixels wide..."

for f in "${png_files[@]}"; do
  filename=$(basename "$f")
  # Use sips to resize while maintaining aspect ratio, suppress stdout
  sips --resampleWidth "$WIDTH" "$f" --out "$DEST_DIR/$filename" > /dev/null
  echo "  -> Created $filename"
done

echo "Done!"
