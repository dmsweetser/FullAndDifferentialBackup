$sourceDirectories = @("C:\test1", "C:\test2")
$backupLocation = "H:\Backups\test"
$backupFrequency = 7
$maxFullBackups = 5

# Full Backup Function
function FullBackup {
    Write-Host "Initiating Full Backup..."

    # Get the backup target object
    $backupTarget = Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='$backupLocation'"

    # Get the existing full backups
    $fullBackups = Get-ChildItem -Path $backupLocation -Filter "*_Full" | Sort-Object LastWriteTime -Descending

    # Check the number of full backups and the available disk space
    if ($fullBackups.Count -ge $maxFullBackups -or $backupTarget.FreeSpace -lt $backupTarget.Size * 0.1) {
        # Delete the oldest full backup
        Write-Host "Deleting the oldest full backup: $($fullBackups[-1].Name)"
        Remove-Item -Path $fullBackups[-1].FullName -Recurse -Force
    }

    # Create a new full backup folder
    $fullBackupFolder = Join-Path -Path $backupLocation -ChildPath ((Get-Date -Format "yyyyMMdd_HHmmss") + "_Full")
    Write-Host "Creating Full Backup Folder: $fullBackupFolder"
    New-Item -ItemType Directory -Path $fullBackupFolder -Force

    # Copy the source directories to the full backup folder
    foreach ($sourceDirectory in $sourceDirectories) {
        Write-Host "Copying $sourceDirectory to $fullBackupFolder"
        Copy-Item -Path $sourceDirectory -Destination $fullBackupFolder -Recurse -ErrorAction Stop
    }

    Write-Host "Full Backup Completed."
}

# Differential Backup Function
function DifferentialBackup {
    param (
        [string]$lastFullBackupPath
    )

    Write-Host "Initiating Differential Backup..."

    $fullBackups = Get-ChildItem -Path $backupLocation -Filter "*_Full" | Sort-Object LastWriteTime -Descending
    $lastFullBackup = $fullBackups | Select-Object -First 1

    if ($lastFullBackup -ne $null) {
        $lastFullBackupPath = $lastFullBackup.FullName
        Write-Host "Latest Full Backup Found: $lastFullBackupPath"

        $diffBackupFolder = Join-Path -Path $backupLocation -ChildPath ((Get-Date -Format "yyyyMMdd_HHmmss") + "_Diff")
        Write-Host "Creating Differential Backup Folder: $diffBackupFolder"
        New-Item -ItemType Directory -Path $diffBackupFolder -Force

        $sourceFiles = Get-ChildItem -Path $sourceDirectories -File -Recurse

        foreach ($file in $sourceFiles) {
            $filePathWithoutDriveLetter = Split-Path -Path $file.FullName -NoQualifier
            $lastFullBackupFile = Join-Path -Path $lastFullBackupPath -ChildPath $filePathWithoutDriveLetter

            if (-not (Test-Path -Path $lastFullBackupFile) -or ($file.LastWriteTime -gt (Get-Item $lastFullBackupFile).LastWriteTime)) {
                Write-Host "Detected change or new file: $file"

                $destinationPath = Join-Path -Path $diffBackupFolder -ChildPath $filePathWithoutDriveLetter
                $destinationDirectory = [System.IO.Path]::GetDirectoryName($destinationPath)

                if (-not (Test-Path -Path $destinationDirectory)) {
                    Write-Host "Creating directory: $destinationDirectory"
                    New-Item -ItemType Directory -Path $destinationDirectory -Force
                }

                Write-Host "Copying $file to $destinationPath"
                Copy-Item -Path $file.FullName -Destination $destinationPath -ErrorAction Stop
            }
        }

        Write-Host "Differential Backup Completed."
    } else {
        Write-Host "No full backup found. Cannot perform a differential backup."
    }
}

# Check for the last full backup
$fullBackups = Get-ChildItem -Path $backupLocation -Filter "*_Full" | Sort-Object LastWriteTime -Descending
$lastFullBackup = $fullBackups | Select-Object -First 1

# Check for conditions to perform a full or differential backup
if ($lastFullBackup -eq $null -or (Get-Date).Subtract($lastFullBackup.LastWriteTime).TotalDays -ge $backupFrequency) {
    Write-Host "Performing Full Backup..."
    FullBackup
} else {
    Write-Host "Performing Differential Backup..."
    DifferentialBackup $lastFullBackup.FullName
}
