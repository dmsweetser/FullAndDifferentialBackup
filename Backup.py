# Bing made this

import os
import shutil
import logging
from datetime import datetime

def configure_logging(destination_dir):
    log_file = os.path.join(destination_dir, 'backup.log')
    logging.basicConfig(filename=log_file, level=logging.DEBUG,
                        format='%(asctime)s [%(levelname)s]: %(message)s')

def create_full_backup(source_dir, destination_dir):
    backup_time = datetime.now().strftime("%Y%m%d%H%M%S")
    source_dir_name = os.path.basename(os.path.normpath(source_dir))
    backup_folder = os.path.join(destination_dir, f"full_backup_{source_dir_name}_{backup_time}")

    logging.info(f"Creating full backup of {source_dir} to {backup_folder}")

    try:
        shutil.copytree(source_dir, backup_folder)
        logging.info("Full backup created successfully")
    except Exception as e:
        logging.error(f"Error creating full backup: {str(e)}")
        logging.warning(f"Skipping {source_dir} due to error.")

def create_differential_backup(source_dir, last_full_backup, destination_dir):
    backup_time = datetime.now().strftime("%Y%m%d%H%M%S")
    source_dir_name = os.path.basename(os.path.normpath(source_dir))
    backup_folder = os.path.join(destination_dir, f"differential_backup_{source_dir_name}_{backup_time}")

    logging.info(f"Creating differential backup of {source_dir} to {backup_folder}")

    # Function to determine if a file should be copied to the differential backup
    def should_copy(file_path):
        file_modification_time = os.path.getmtime(file_path)
        return not os.path.exists(os.path.join(last_full_backup, os.path.relpath(file_path))) or file_modification_time > os.path.getmtime(os.path.join(last_full_backup, os.path.relpath(file_path)))

    # Copy files to the differential backup
    for root, _, files in os.walk(source_dir):
        for file in files:
            file_path = os.path.join(root, file)
            relative_path = os.path.relpath(file_path, source_dir)
            destination_file_path = os.path.join(backup_folder, relative_path)

            try:
                if should_copy(file_path):
                    logging.info(f"Copying {file_path} to {destination_file_path}")
                    shutil.copy2(file_path, destination_file_path)
            except Exception as e:
                logging.error(f"Error copying {file_path}: {str(e)}")
                logging.warning(f"Skipping {file_path} due to error.")

    logging.info("Differential backup created successfully")

def remove_oldest_backup(destination_dir, retain_count):
    backups = sorted(os.listdir(destination_dir), key=lambda x: os.path.getctime(os.path.join(destination_dir, x)))

    while len(backups) > retain_count:
        oldest_backup = os.path.join(destination_dir, backups[0])
        logging.info(f"Removing oldest backup: {oldest_backup}")

        try:
            shutil.rmtree(oldest_backup)
        except Exception as e:
            logging.error(f"Error removing {oldest_backup}: {str(e)}")
            logging.warning(f"Skipping {oldest_backup} due to error.")

        backups = backups[1:]

def perform_backup(source_dirs, destination_dir, retain_count):
    # Ensure destination directory exists
    if not os.path.exists(destination_dir):
        os.makedirs(destination_dir)

    configure_logging(destination_dir)

    for source_dir in source_dirs:
        # Check if a full backup already exists
        full_backups = [f for f in os.listdir(destination_dir) if f.startswith(f"full_backup_{os.path.basename(os.path.normpath(source_dir))}")]
        
        if full_backups:
            last_full_backup = os.path.join(destination_dir, max(full_backups))
            create_differential_backup(source_dir, last_full_backup, destination_dir)
        else:
            create_full_backup(source_dir, destination_dir)

    remove_oldest_backup(destination_dir, retain_count)

if __name__ == "__main__":
    source_directories = ["C:\\Files1", "C:\\Files2"]
    destination_directory = "H:\\Backups"
    retention_count = 7

    perform_backup(source_directories, destination_directory, retention_count)
