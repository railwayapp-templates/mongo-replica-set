#!/bin/bash

# Path to the keyfile and database directory
KEYFILE_PATH="/data/keyfile"
DB_PATH="/data/db"

# Check if the keyfile already exists
if [ -f "$KEYFILE_PATH" ]; then
  echo "Keyfile already exists at $KEYFILE_PATH. Skipping keyfile generation."
else
  # Generate the keyfile from the environment variable
  if [ -z "$KEYFILE" ]; then
    echo "KEYFILE environment variable is not set. Exiting."
    exit 1
  fi

  echo "Generating keyfile from environment variable..."
  echo "$KEYFILE" > "$KEYFILE_PATH"
  chown mongodb:mongodb "$KEYFILE_PATH"
  chmod 600 "$KEYFILE_PATH"
fi

# Ensure the database directory exists
if [ ! -d "$DB_PATH" ]; then
  echo "Creating MongoDB data directory at $DB_PATH..."
  mkdir -p "$DB_PATH"
  chown -R mongodb:mongodb "$DB_PATH"
fi
