# Full and Differential Backup

## Overview
This is a Python script for creating and managing full and differential backups of specified source directories. The script is designed to run periodically to ensure data integrity and minimize storage usage. It performs full backups at a defined interval and creates differential backups for the changes between full backups.

## Features
- **Full Backup:** Creates a full backup of the specified source directory and saves it to the destination directory. Full backups are created at a defined interval.
- **Differential Backup:** Creates a differential backup of the changes in the source directory since the last full backup. Differential backups are stored separately in the destination directory.
- **Backup Retention:** Manages the number of backups retained in the destination directory. Older backups beyond the specified retention count are automatically removed.
- **Logging:** The script maintains a log file (`backup.log`) to record the details of each backup operation, including successes and errors.

## How to Use
1. **Source Directories:** Modify the `source_directories` list to include the paths of the directories you want to back up.
2. **Destination Directory:** Set the `destination_directory` variable to the location where you want to store the backups.
3. **Retention Count:** Adjust the `retention_count` variable to specify the number of backups to retain in the destination directory.
4. **Full Backup Interval:** Set the `full_backup_interval_days` variable to determine how often a full backup should be performed.

## Usage Example
```python
if __name__ == "__main__":
    source_directories = ["C:\\Files", "C:\\Users\\Daniel"]
    destination_directory = "H:\\Backups_New"
    retention_count = 7
    full_backup_interval_days = 14

    perform_backup(source_directories, destination_directory, retention_count, full_backup_interval_days)

## Dependencies
- Python 3.x
- No additional external libraries are required.

## Notes

- Ensure that the script is run periodically using a scheduler (e.g., cron on Unix-like systems or Task Scheduler on Windows) to maintain regular backups.
- Review the log file (backup.log) for detailed information on each backup operation.

Feel free to customize the script according to your specific requirements.