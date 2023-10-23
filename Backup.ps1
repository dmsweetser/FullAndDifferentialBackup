# Configuration
$sourceDirectories = @("C:\Files1", "C:\Files2")  # List of source directories to back up
$backupLocation = "H:\Backups"  # Updated target location for backups
$backupFrequency = 7  # Days between full backups

# Create a unique backup folder based on the current date
$backupFolder = Join-Path -Path $backupLocation -ChildPath (Get-Date -Format "yyyyMMdd")
New-Item -ItemType Directory -Path $backupFolder -Force

# Function to create the 'FullBackup' folder and perform a full backup
function FullBackup {
    $fullBackupFolder = Join-Path -Path $backupFolder -ChildPath "FullBackup"
    New-Item -ItemType Directory -Path $fullBackupFolder -Force  # Create FullBackup folder
    Copy-Item -Path $sourceDirectories -Destination $fullBackupFolder -Recurse
}

# Function to perform a differential backup
function DifferentialBackup {
    $diffBackupFolder = Join-Path -Path $backupFolder -ChildPath "DifferentialBackup"
    New-Item -ItemType Directory -Path $diffBackupFolder -Force  # Create DifferentialBackup folder
    Copy-Item -Path $sourceDirectories -Destination $diffBackupFolder -Recurse -Force
}

# Function to clean up old backups when disk space is low
function CleanUpBackups {
    $backupDrive = [System.IO.Path]::GetPathRoot($backupLocation).TrimEnd('\').TrimEnd(':')
    while ((Get-PSDrive -Name $backupDrive).Free -lt 1gb) {
        $backups = Get-ChildItem -Path $backupLocation | Sort-Object CreationTime
        $oldestBackup = $backups[0]
        Remove-Item -Path $oldestBackup.FullName -Recurse -Force
    }
}

# Check if it's time for a full backup
if (!(Test-Path $backupFolder)) {
    FullBackup
} else {
    $lastFullBackup = Get-ChildItem -Path (Join-Path -Path $backupFolder -ChildPath "FullBackup") -ErrorAction SilentlyContinue
    if ($lastFullBackup -eq $null) {
        FullBackup
    } else {
        $daysSinceLastFullBackup = [math]::Round((Get-Date - $lastFullBackup.CreationTime).TotalDays)  # Calculate the days difference
        if ($daysSinceLastFullBackup -ge $backupFrequency) {
            FullBackup
        } else {
            DifferentialBackup
        }
    }
}

# Clean up old backups if disk space is low
CleanUpBackups
