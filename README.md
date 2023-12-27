 # Full and Differential Backup
_This script was mostly built by generative AI_

This script is designed to create full, differential, and incremental backups of specified source directories and maintain a certain number of backups based on the retention policy. It also logs backup sizes and handles errors when creating backups or removing old ones. The script uses `glob` for better performance and checks if the source directory is empty before creating a backup to avoid unnecessary operations. The script executes in a virtual environment to maintain an independent set of the prerequisite packages. It runs in Python 3.12.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Installation](#installation)
3. [Configuration](#configuration)
4. [Functions](#functions)
5. [Usage](#usage)
6. [Logging and Notifications](#logging-and-notifications)
7. [Compression](#compression)
8. [Error Handling](#error-handling)
9. [Retention Policy](#retention-policy)
10. [Running the Script](#running-the-script)

## Prerequisites
- Python 3.12
- Access to the source directories and destination directory
- Required permissions to read, write, and create directories in the specified paths

## Installation
To install, download the files from the repository and run the following:
```
.\install.bat
```

## Configuration
1. Modify the `source_directories`, `destination_directory`, `retention_count`, and `backup_interval_days` variables in the script according to your requirements.
2. Configure logging settings by updating the `configure_logging()` function if needed.

## Functions
The script includes the following functions:
1. `configure_logging(destination_dir)`: Configures the logger with a specified destination directory for the log file.
2. `create_full_backup(source_dir, destination_dir)`: Creates a full backup of a source directory and its contents to a new backup folder.
3. `should_copy(file_path, last_full_or_diff_backup)`: Determines if a file needs to be copied during differential or incremental backup based on its modification time.
4. `create_differential_backup(source_dir, last_full_backup, destination_dir)`: Creates a differential backup of a source directory by copying only the changed files to the new backup folder.
5. `create_incremental_backup(source_dir, last_full_or_diff_backup, destination_dir)`: Creates an incremental backup of a source directory by copying only the changed files since the last full or differential backup.
6. `remove_oldest_backups(destination_dir, retain_count)`: Removes the oldest backups from the destination directory based on retention count and backup type (full, differential, or incremental).
7. `should_create_backup(source_dir, destination_dir, retain_count, backup_interval_days)`: Checks if it's time to create a full, differential, or incremental backup for a source directory based on the last full, differential, or incremental backup and retention policy.
8. `perform_backup(source_dirs, destination_dir, retain_count, backup_interval_days)`: Performs the backup process based on the provided source directories, destination directory, retention count, and backup interval days.
9. `log_backup_size(destination_dir)`: Logs backup sizes and sends notifications if applicable
10. `compress_backup(backup_folder, destination_dir)`: Compresses the full backup using gzip

## Usage
To use the script, simply execute the provided batch file:
```
.\run.bat
```
The script will automatically determine which type of backup to create for each source directory based on the retention policy and last backups.

## Logging and Notifications
The script logs backup sizes and sends notifications if applicable using the `log_backup_size()` function

## Compression
The script compresses full backups using gzip with the `compress_backup()` function.

## Error Handling
The script handles errors when creating backups or removing old ones by logging error messages and continuing with the next backup operation.

## Retention Policy
The script maintains a certain number of backups based on the retention policy by removing the oldest backups when the limit is reached.

## Running the Script
To run the script, simply execute the provided batch file:
```
.\run.bat
```
Make sure to have the correct permissions and access to the source directories and destination directory before running the script.