$sourceDirectories = @("C:\Files1", "C:\Files2")
$backupLocation = "H:\Backups"
$backupFrequency = 7
$maxFullBackups = 5

# Full Backup Function
function FullBackup {
    Write-Host "Initiating Full Backup..."

    $fullBackupFolder = Join-Path -Path $backupLocation -ChildPath ((Get-Date -Format "yyyyMMdd_HHmmss") + "_Full")
    Write-Host "Creating Full Backup Folder: $fullBackupFolder"
    New-Item -ItemType Directory -Path $fullBackupFolder -Force

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

    foreach ($sourceDirectory in $sourceDirectories) {
        Write-Host "Checking changes in $sourceDirectory since the last full backup..."
        $sourceFiles = Get-ChildItem -Path $sourceDirectory -File -Recurse

        foreach ($file in $sourceFiles) {
			$filePathWithoutDriveLetter = Split-Path -Path $file.FullName -NoQualifier
			$lastFullBackupFile = Join-Path -Path $lastFullBackupPath -ChildPath $filePathWithoutDriveLetter

			Write-Host "Comparing $file to $lastFullBackupFile"

            if ((Test-Path -Path $lastFullBackupFile) -and ($file.LastWriteTime -gt (Get-Item $lastFullBackupFile).LastWriteTime)) {
                    Write-Host "Detected change in file: $file"
					
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
