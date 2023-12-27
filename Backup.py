# Backup script to create full, differential, and incremental backups of specified source directories and maintain a certain number of backups based on retention policy. It also logs backup sizes and handles errors when creating backups or removing old ones. The script uses `glob` for better performance and checks if the source directory is empty before creating a backup to avoid unnecessary operations.

import os
import shutil
import logging
import time
import datetime
import glob
import gzip
import threading

# Configure logger
def configure_logging(destination_dir):
    log_file = os.path.join(destination_dir, 'backup.log')
    logging.basicConfig(filename=log_file, level=logging.DEBUG,
                        format='%(asctime)s [%(levelname)s]: %(message)s')

# Create full backup of a source directory and its contents to a new backup folder
def create_full_backup(source_dir, destination_dir):

    backup_time = datetime.datetime.now().strftime("%Y%m%d%H%M%S")
    
    # Determine the name of the new full backup folder based on the source directory and backup time
    source_dir_name = os.path.basename(os.path.normpath(source_dir))
    backup_folder = os.path.join(destination_dir, f"full_backup_{source_dir_name}_{backup_time}")

    # Create the full backup folder and copy all files from the source directory to it
    logging.info(f"Creating full backup of {source_dir} to {backup_folder}")
    if not os.path.exists(source_dir) or not os.access(source_dir, os.R_OK):
        logging.warning(f"{source_dir} does not exist or is not accessible.")
        return
    try:
        shutil.copytree(source_dir, backup_folder)
        compress_backup(backup_folder, destination_dir)  # Compress the full backup using gzip
        logging.info("Full backup created successfully")
    except Exception as e:
        logging.error(f"Error creating full backup: {str(e)}")
        logging.warning(f"Skipping {source_dir} due to error.")

# Determine if a file needs to be copied during differential or incremental backup based on its modification time
def should_copy(file_path, last_full_or_diff_backup):
    destination_file_path = os.path.join(last_full_or_diff_backup, os.path.relpath(file_path))

    # Ensure the destination directory exists
    destination_dir = os.path.dirname(destination_file_path)
    if not os.path.exists(destination_dir):
        os.makedirs(destination_dir)

    return not os.path.exists(destination_file_path) or os.path.getmtime(file_path) > os.path.getmtime(destination_file_path)

# Create differential backup of a source directory by copying only the changed files to the new backup folder
def create_differential_backup(source_dir, last_full_backup, destination_dir):
    
    backup_time = datetime.datetime.now().strftime("%Y%m%d%H%M%S")
    
    # Determine the name of the new differential backup folder based on the source directory, last full backup, and backup time
    source_dir_name = os.path.basename(os.path.normpath(source_dir))
    backup_folder = os.path.join(destination_dir, f"differential_backup_{source_dir_name}_{last_full_backup}_{backup_time}")

    # Create the differential backup folder structure
    logging.info(f"Creating differential backup directory structure of {source_dir} to {backup_folder}")
    try:
        os.makedirs(backup_folder, exist_ok=True)
    except Exception as e:
        logging.error(f"Error creating differential backup directory structure: {str(e)}")
        logging.warning(f"Skipping {source_dir} due to error.")

        return

    # Now, copy only the changed files
    for root, _, files in os.walk(source_dir):
        for file in files:
            file_path = os.path.join(root, file)
            relative_path = os.path.relpath(file_path, source_dir)
            destination_file_path = os.path.join(backup_folder, relative_path)

            try:
                if should_copy(file_path, last_full_backup):
                    logging.info(f"Copying {file_path} to {destination_file_path}")
                    shutil.copy2(file_path, destination_file_path)
            except Exception as e:
                logging.error(f"Error copying {file_path}: {str(e)}")
                logging.warning(f"Skipping {file_path} due to error.")

    logging.info("Differential backup created successfully")

# Create incremental backup of a source directory by copying only the changed files since the last full or differential backup
def create_incremental_backup(source_dir, last_full_or_diff_backup, destination_dir):
    
    backup_time = datetime.datetime.now().strftime("%Y%m%d%H%M%S")
    
    # Determine the name of the new incremental backup folder based on the source directory, last full or differential backup, and backup time
    source_dir_name = os.path.basename(os.path.normpath(source_dir))
    backup_folder = os.path.join(destination_dir, f"incremental_backup_{source_dir_name}_{last_full_or_diff_backup}_{backup_time}")

    # Create the incremental backup folder structure
    logging.info(f"Creating incremental backup directory structure of {source_dir} to {backup_folder}")
    try:
        os.makedirs(backup_folder, exist_ok=True)
    except Exception as e:
        logging.error(f"Error creating incremental backup directory structure: {str(e)}")
        logging.warning(f"Skipping {source_dir} due to error.")

        return

    # Now, copy only the changed files since the last full or differential backup
    for root, _, files in os.walk(source_dir):
        for file in files:
            file_path = os.path.join(root, file)
            relative_path = os.path.relpath(file_path, source_dir)
            destination_file_path = os.path.join(backup_folder, relative_path)

            try:
                if should_copy(file_path, last_full_or_diff_backup):
                    logging.info(f"Copying {file_path} to {destination_file_path}")
                    shutil.copy2(file_path, destination_file_path)
            except Exception as e:
                logging.error(f"Error copying {file_path}: {str(e)}")
                logging.warning(f"Skipping {file_path} due to error.")

    logging.info("Incremental backup created successfully")

# Remove the oldest backups from the destination directory based on retention count and backup type (full, differential, or incremental)
def remove_oldest_backups(destination_dir, retain_count):
    
    backups = sorted([f for f in glob.glob(os.path.join(destination_dir, "full_backup_*|differential_backup_*|incremental_backup_*"))], key=lambda x: os.path.getctime(x))

    while len(backups) > retain_count:
        oldest_backup = backups[0]
        backup_path = os.path.join(destination_dir, oldest_backup)
        logging.info(f"Removing oldest backup: {oldest_backup}")

        try:
            shutil.rmtree(backup_path)
        except Exception as e:
            logging.error(f"Error removing {oldest_backup}: {str(e)}")
            logging.warning(f"Skipping {oldest_backup} due to error.")

        backups = backups[1:]

# Check if it's time to create a full, differential, or incremental backup for a source directory based on the last full, differential, or incremental backup and retention policy
def should_create_backup(source_dir, destination_dir, retain_count, backup_interval_days):
    
    last_full_backups = [f for f in glob.glob(os.path.join(destination_dir, "full_backup_*_{}".format(source_dir))) if os.path.isfile(f)]
    last_diff_or_incr_backups = [f for f in glob.glob(os.path.join(destination_dir, "differential_backup_*|incremental_backup_*")) if os.path.isfile(f) and f.startswith(source_dir)]

    last_full_or_diff_backup = None

    if len(last_diff_or_incr_backups) > 0:
        last_full_or_diff_backup = max(last_full_backups, key=lambda x: os.path.getctime(x)) if last_full_backups else max(last_diff_or_incr_backups, key=lambda x: os.path.getctime(x))
    
    # Check if it's time to create a new full backup
    if not last_full_or_diff_backup or (datetime.datetime.now() - datetime.datetime.fromtimestamp(os.path.getctime(last_full_or_diff_backup))).days >= backup_interval_days:
        return "full"

    # Check if it's time to create a new differential or incremental backup
    last_full_backup = last_full_backups[0] if last_full_or_diff_backup else last_diff_or_incr_backups[0]
    return "differential" if (datetime.datetime.now() - datetime.datetime.fromtimestamp(os.path.getctime(last_full_backup))).days >= backup_interval_days else "incremental"

# Perform the backup process based on the provided source directories, destination directory, retention count, and backup interval days
def perform_backup(source_dirs, destination_dir, retain_count, backup_interval_days):
    if not os.path.exists(destination_dir):
        logging.error("Destination directory does not exist.")
        return

    configure_logging(destination_dir)

    thread_pool = []

    for source_dir in source_dirs:
        backup_type = should_create_backup(source_dir, destination_dir, retain_count, backup_interval_days)

        if backup_type == "full":
            t = threading.Thread(target=create_full_backup, args=(source_dir, destination_dir))
            t.start()
            thread_pool.append(t)
        elif backup_type == "differential":
            last_full_or_diff_backup = max([f for f in glob.glob(os.path.join(destination_dir, "full_backup_*"))], key=lambda x: os.path.getctime(x))
            t = threading.Thread(target=create_differential_backup, args=(source_dir, last_full_or_diff_backup, destination_dir))
            t.start()
            thread_pool.append(t)
        elif backup_type == "incremental":
            last_full_or_diff_backup = max([f for f in glob.glob(os.path.join(destination_dir, "differential_backup_*|incremental_backup_*"))], key=lambda x: os.path.getctime(x))
            t = threading.Thread(target=create_incremental_backup, args=(source_dir, last_full_or_diff_backup, destination_dir))
            t.start()
            thread_pool.append(t)

    for t in thread_pool:
        t.join()

    remove_oldest_backups(destination_dir, retain_count)
    log_backup_size(destination_dir)

# Log backup sizes and send notifications if applicable
def log_backup_size(destination_dir):

    backups = sorted([f for f in glob.glob(os.path.join(destination_dir, "full_backup_*|differential_backup_*|incremental_backup_*"))], key=lambda x: os.path.getctime(x))

    logging.info("Backup sizes:")
    for backup in backups:
        size = os.path.getsize(backup)
        logging.info(f"{backup}: {size} bytes")

# Compress the full backup using gzip (TODO: Add compression options)
def compress_backup(backup_folder, destination_dir):
    backup_name = os.path.basename(backup_folder)
    compressed_backup = f"{backup_name}.gz"
    compressed_backup_path = os.path.join(destination_dir, compressed_backups[0])

    logging.info(f"Compressing {backup_folder} to {compressed_backup_path}")
    try:
        with open(backup_name, 'rb') as f_in:
            with gzip.open(compressed_backup, 'wb') as f_out:
                shutil.copyfileobj(f_in, f_out)
        os.remove(backup_folder)  # Remove the uncompressed backup folder
    except Exception as e:
        logging.error(f"Error compressing {backup_folder}: {str(e)}")
        logging.warning(f"Skipping compression of {backup_folder} due to error.")

if __name__ == "__main__":
    source_directories = ["C:\\Files", "C:\\Users\\Daniel"]
    destination_directory = "H:\\Backups"
    retention_count = 7
    backup_interval_days = 14

    perform_backup(source_directories, destination_directory, retention_count, backup_interval_days)