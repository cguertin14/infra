#!/bin/bash

set -e

# Make sure to pass the backup_id as an argument
if [[ $# -eq 0 ]]; then
  echo "Error: No arguments provided."
  echo "Usage: $0 <backup_id>"
  exit 1
fi
backup_id=$1

echo "WARNING: This script assumes that 'imessage-exporter', 'pv' and 'b2-tools' are installed"
echo "WARNING: Make sure to have authenticated with 'b2' and 'b2 account authorize'"

# Run imessage-exporter to backup the database
imessage-exporter -a iOS -f html -o backup --db-path "$HOME/Library/Application Support/MobileSync/Backup/$backup_id" -c full

# # Tar + Zip the backup and print progress while it's being zipped
backup_file_name="$(date +%s)-imessages.tar.gz"
tar cf - backup |  pv -s $(($(du -sk backup | awk '{print $1}') * 1024)) | gzip > $backup_file_name

# Upload the backup to B2
b2 file upload ios-backups-bucket $backup_file_name $backup_file_name
echo "Backup uploaded to B2 :D"

# Cleanup
rm -rf backup $backup_file_name