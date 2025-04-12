#!/bin/bash

# Load variables from .env
set -a 
source .env
set +a


# Check if jq is installed
if ! command -v jq &> /dev/null; then
  echo "Error: 'jq' is required but not found. You can install it with 'brew install jq'."
  exit 1
fi

# Check if DEST_DIR is defined
if [ -z "$DEST_DIR" ]; then
    echo "DEST_DIR is not defined. Did you create a .env file based on .env.example?"
    exit 1
fi

#Check if the folder exists
mkdir -p "$DEST_DIR"


#Initialise the timestamp of the archive
TIMESTAMP=$(date "+%Y-%m-%d_%H-%M-%S")

# Read the folders you want to sync, from .folders.json
FOLDERS=$(jq -r '.folders[]' .folders.json)

CHECKSUM_FILE=./last-checksums.json

#Check if the checksum file exists
if [ ! -f "$CHECKSUM_FILE" ] || ! jq -e . "$CHECKSUM_FILE" > /dev/null 2>&1; then
  echo "{}" > "$CHECKSUM_FILE"
fi


generate_folder_checksum()
{
  local folder="$1"
  find "$folder" -type f \
    -not -path "*/node_modules/*" \
    -not -path "*/.git/*" \
    -not -path "*/dist/*" \
    -not -path "*/build/*" \
    -exec shasum {} \; \
    | shasum \
    | cut -d ' ' -f1 
}

perform_backup() 
{
  local folder="$1"
  local folder_expanded=$(eval echo "$folder")
  local basename=$(basename "$folder_expanded")
  local archive_name="${basename}-backup-${TIMESTAMP}.tar.gz"

  #echo "Compressing $folder → $archive_name..."
  tar --exclude='node_modules' \
      --exclude='.git' \
      --exclude='dist' \
      --exclude='build' \
      -czf "$archive_name" \
      -C "$(dirname "$folder_expanded")" "$basename"

  #echo "Compression finished, sending to Proton Drive..."
  rsync -av "$archive_name" "$DEST_DIR/"

  rm "$archive_name"
  #echo "Backup completed : $basename"
}

for FOLDER in $FOLDERS; do
  FOLDER_EXPANDED=$(eval echo "$FOLDER")
  if [ -d "$FOLDER_EXPANDED" ]; then
    CHECKSUM=$(generate_folder_checksum "$FOLDER_EXPANDED")
    OLD_SUM=$(jq -r --arg path "$FOLDER_EXPANDED" '.[$path] // empty' "$CHECKSUM_FILE")

    if [ "$CHECKSUM" != "$OLD_SUM" ]; then
      echo "Running backup for $FOLDER..."
      perform_backup "$FOLDER"
      jq --arg path "$FOLDER_EXPANDED" --arg sum "$CHECKSUM" \
        '. + {($path): $sum}' "$CHECKSUM_FILE" > tmp.json && mv tmp.json "$CHECKSUM_FILE"
    else
      echo "$FOLDER already uptodate → skipping backup."
    fi
  else
    echo "Folder not found: $FOLDER"
  fi
done

echo "All backup completed"




