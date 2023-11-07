# PowerShell Backup Script

This script performs a full or differential backup of the specified source directories to a backup location.

## Parameters

- `$sourceDirectories`: An array of strings that contains the paths of the source directories to be backed up.
- `$backupLocation`: A string that contains the path of the backup location where the backup folders will be created.
- `$backupFrequency`: An integer that specifies the number of days between full backups. If the last full backup is older than this value, a new full backup will be performed. Otherwise, a differential backup will be performed.
- `$maxFullBackups`: An integer that specifies the maximum number of full backups to keep. Older full backups will be deleted when this limit is reached.

## Functions

- `FullBackup`: This function creates a full backup of the source directories in a folder named with the current date and time and the suffix `_Full`. It uses the `Write-Host`, `Join-Path`, `New-Item`, and `Copy-Item` cmdlets to perform the backup operation.
- `DifferentialBackup`: This function creates a differential backup of the source directories in a folder named with the current date and time and the suffix `_Diff`. It compares the last write time of the source files with the corresponding files in the latest full backup folder and copies only the changed or new files. It uses the `Write-Host`, `Join-Path`, `New-Item`, `Get-ChildItem`, `Test-Path`, `Get-Item`, and `Copy-Item` cmdlets to perform the backup operation.

## Usage

To run the script, you need to modify the parameter values according to your needs. Then, you can execute the script from a PowerShell console or schedule it as a task using the `Task Scheduler` tool.