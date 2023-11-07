# PowerShell Backup

## Overview
This PowerShell script is designed to create and manage backups of specified source directories. It provides options for full and differential backups, ensuring your data is secure and retrievable. Additionally, it includes a cleanup mechanism to manage disk space when it's running low.

## Configuration
Before using this script, you should configure it according to your needs. Open the script and modify the following variables:

- `$sourceDirectories`: An array that should contain the paths of the directories you want to back up.
- `$backupLocation`: The target location where backups will be stored. Make sure this is a valid path.
- `$backupFrequency`: The number of days between full backups. Adjust this value to suit your backup strategy.

## Usage
To use the script:

1. Run the script using PowerShell.
2. It will create a unique backup folder within the specified `$backupLocation` with a timestamp.
3. Check whether it's time for a full backup. The script does this by examining the last full backup's creation time (if available) and comparing it to the `$backupFrequency`.
4. If a full backup is needed, the script will create a "FullBackup" folder and copy all the data from `$sourceDirectories` into it.
5. If it's not time for a full backup, a differential backup will be performed in a "DifferentialBackup" folder.
6. The script will clean up old backups when disk space is low. It checks for available free space and removes the oldest backups if necessary.

## Functions
- `FullBackup`: This function creates a "FullBackup" folder and performs a full backup of all specified source directories.
- `DifferentialBackup`: This function creates a "DifferentialBackup" folder and performs a differential backup of the source directories.
- `CleanUpBackups`: This function is used to clean up old backups when the disk space is running low.
