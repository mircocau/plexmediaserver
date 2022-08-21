#!/bin/bash

# Script to backup Plex Media Server databases only (snap version).
# Tested on Ubuntu 20.04 (21 august 2022)

plex_databases_dir="/var/snap/plexmediaserver/common/Library/Application Support/Plex Media Server/Plug-in Support/Databases"
backups_dir="../backups"

# Stop Plex Media Server (snap)
echo "[INFO] Stopping Plex Media Server (snap) ..."
sudo snap stop plexmediaserver

if [ $? -ne 0 ]
then
    echo "[ERROR] Can't stop Plex Media Server (snap)."
    echo "[INFO] Script NOT completed."
    echo "[INFO] Exiting script."
    exit 1
fi

# Backup & compress
echo "[INFO] Backupping & compressing ..."
sudo tar cz -f "${backups_dir}/$(date '+%Y%m%d_%H%M').tar.gz" -C "${plex_databases_dir}" .

# Start Plex Media Server (snap)
echo "[INFO] Starting Plex Media Server (snap) ..."
sudo snap start plexmediaserver

if [ $? -ne 0 ]
then
    echo "[ERROR] Can't start Plex Media Server (snap)."
    echo "[INFO] Script PARTIALLY completed."
    echo "[INFO] Exiting script."
    exit 1
fi

echo "[INFO] Script completed."
echo "[INFO] Exiting script."
exit 0