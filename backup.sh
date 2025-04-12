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

for FOLDER in $FOLDERS; do
  FOLDER_EXPANDED=$(eval echo "$FOLDERS")

  if [ -d "$FOLDER_EXPANDED" ]; then
    BASENAME=$(basename "$FOLDER_EXPANDED")
    ARCHIVE_NAME="${BASENAME}-backup-${TIMESTAMP}.tar.gz"

    echo "Compressing $FOLDER -> $ARCHIVE_NAME..." 
    tar --exclude='node_modules' \
            --exclude='.git' \
            --exclude='dist' \
            --exclude='build' \
            -czf "$ARCHIVE_NAME" \
            -C "$(dirname "$FOLDER_EXPANDED")" "$BASENAME" 

    echo "Compression finished, sending to Proton Drive"
    rsync -av "$ARCHIVE_NAME" "$DEST_DIR/"

    rm "$ARCHIVE_NAME"
    echo "Backup completed : $BASENAME"
  else
    echo "Error: Folder not found : $FOLDERS"
  fi
done

echo "All backup completed"




