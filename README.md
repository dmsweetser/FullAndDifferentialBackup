# Full and Differential Backup

This script performs full and differential backups of specified directories, handling potential "Access Denied" errors gracefully by moving on to the next file.

## Table of Contents

- [Overview](#overview)
- [Usage](#usage)
- [Configuration](#configuration)
- [Logging](#logging)
- [Error Handling](#error-handling)

## Overview

The backup script is designed to create full and differential backups of specified source directories to a destination directory. It uses a logging system to capture information about the backup process.

## Usage

To use the script, follow these steps:

1. Modify the `source_directories`, `destination_directory`, and `retention_count` variables in the `if __name__ == "__main__":` block according to your requirements.

2. Run the script by executing the following command in your terminal:

    ```bash
    python script_name.py
    ```

Replace `script_name.py` with the actual name of your Python script.

## Configuration

- `source_directories`: List of source directories to be backed up.
- `destination_directory`: The directory where backups will be stored.
- `retention_count`: The number of backups to retain. Older backups will be removed.

## Logging

The script utilizes Python's `logging` module to capture information about the backup process. The logs are written to a file named `backup.log` in the destination directory.

## Error Handling

The script includes error handling to gracefully manage "Access Denied" errors or other exceptions during the backup process. In case of an error, the script logs the details and continues with the backup for other files.

Feel free to customize the script further to suit your specific needs.
