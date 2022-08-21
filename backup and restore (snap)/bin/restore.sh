#!/bin/bash

# Script to restore Plex Media Server databases from backup (snap version).
# Tested on Ubuntu 20.04 (21 august 2022)

plex_databases_dir="/var/snap/plexmediaserver/common/Library/Application Support/Plex Media Server/Plug-in Support/Databases"
backups_dir="../backups"
mkdir "${backups_dir}"

backups_filename_path_array=()
backups_datetime_array=()

# Check if there are any local backups inside 'backups' directory
if [ ! -n "$(ls -A ${backups_dir} 2>/dev/null)" ]
then
  # Directory is empty (or does not exist)
  echo "[INFO] No local backups found."
  echo "[INFO] Exiting script."
  exit 0
fi

# List all local backups
echo "List of local backups:"

index=0
for filename_path in ${backups_dir}/*.tar.gz
do
    backups_filename_path_array=("${filename_path}")

    filename="${filename_path#${backups_dir}/}"
    filename="${filename%.*}"
    filename="${filename%.*}"
    filename="${filename//_/ }"

    backups_datetime_array+=("$(date -d "${filename}" '+%d-%m-%Y %H:%M')");

    echo "ID: ${index} -- ${backups_datetime_array[${index}]}"
    
    index=$((index+1))
done

# Prompt for the backup index (or ID) to restore
echo ""
echo "Choose a backup to restore:"
read -p "ID: " index_input

if [ ${index_input} -ge 0 ] && [ ${index_input} -lt "${#backups_filename_path_array[@]}" ]
then
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

    # Extract backup archive
    echo "[INFO] Extracting backup archive ..."
    directory="${backups_filename_path_array[${index_input}]#${backups_dir}/}"
    directory="${directory%.*}"
    directory="${directory%.*}"
    mkdir "${backups_dir}/${directory}"

    tar -xf "${backups_filename_path_array[${index_input}]}" -C "${backups_dir}/${directory}"

    if [ $? -ne 0 ]
    then
        echo "[ERROR] Can't extract archive."
        echo "[INFO] Script NOT completed."
        # Delete temp file
        rm -r "${backups_dir}/${directory}"
        echo "[INFO] Exiting script."
        exit 1
    fi

    echo "[INFO] Archive extracted."

    # Restore
    # Delete existing Plex Media Server databases
    echo "[INFO] Deleting existing Plex Media Server databases ..."
    sudo rm "${plex_databases_dir}"/*

    if [ $? -ne 0 ]
    then
        echo "[ERROR] Can't delete existing Plex Media Server databases."
        echo "[INFO] Script NOT completed."
        # Delete temporary file
        rm -r "${backups_dir}/${directory}"
        echo "[INFO] Exiting script."
        exit 1;
    fi

    echo "[INFO] Existing databases deleted."

    # Copy backup database
    echo "[INFO] Copying backup databases ..."
    sudo cp "${backups_dir}/${directory}"/* "${plex_databases_dir}"

    if [ $? -ne 0 ]
    then
        echo "[ERROR] Can't copy backup databases."
        echo "[INFO] Script NOT completed."
        # Delete temp file
        rm -r "${backups_dir}/${directory}"
        echo "[INFO] Exiting script."
        exit 1;
    fi

    # Delete temp file
    rm -r "${backups_dir}/${directory}"

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
else
    echo "[ERROR] ID not valid."
    echo "[INFO] Script NOT completed."
    echo "[INFO] Exiting script."
    exit 1;
fi

echo "[INFO] Script completed."
echo "[INFO] Exiting script."
exit 0