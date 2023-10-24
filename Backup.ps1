# Configuration
$sourceDirectories = @("C:\Files1", "C:\Files2")  # List of source directories to back up
$backupLocation = "H:\Backups"  # Updated target location for backups
$backupFrequency = 7  # Days between full backups
$maxFullBackups = 5    # Maximum number of full backups to keep

# Function to create a full backup
function FullBackup {
    $fullBackupFolder = Join-Path -Path $backupLocation -ChildPath ((Get-Date -Format "yyyyMMdd_HHmmss") + "_Full")
    New-Item -ItemType Directory -Path $fullBackupFolder -Force
    Copy-Item -Path $sourceDirectories -Destination $fullBackupFolder -Recurse
}

# Function to create a differential backup
function DifferentialBackup {
    $fullBackups = Get-ChildItem -Path $backupLocation -Filter "*_Full" | Sort-Object CreationTime
    $lastFullBackup = $fullBackups | Select-Object -Last 1
    if ($lastFullBackup -ne $null) {
        $diffBackupFolder = Join-Path -Path $backupLocation -ChildPath ((Get-Date -Format "yyyyMMdd_HHmmss") + "_Diff")
        New-Item -ItemType Directory -Path $diffBackupFolder -Force
        $differentialItems = Compare-Object -ReferenceObject (Get-ChildItem -Path $sourceDirectories -File) -DifferenceObject (Get-ChildItem -Path $lastFullBackup.FullName -File)
        $differentialItems | ForEach-Object {
            $sourcePath = $_.InputObject.FullName
            $relativePath = $sourcePath.Substring($sourcePath.IndexOf($lastFullBackup.FullName) + $lastFullBackup.FullName.Length + 1)
            $destinationPath = Join-Path -Path $diffBackupFolder -ChildPath $relativePath
            Copy-Item -Path $sourcePath -Destination $destinationPath
        }
    }
}

# Function to clean up old backups if they exceed the maximum number of full backups
function CleanUpBackups {
    $fullBackups = Get-ChildItem -Path $backupLocation -Filter "*_Full" | Sort-Object CreationTime
    $excessFullBackups = $fullBackups | Select-Object -Skip $maxFullBackups
    $excessFullBackups | ForEach-Object {
        Remove-Item -Path $_.FullName -Recurse -Force
    }
}

# Check if it's time for a full backup or differential backup
$fullBackups = Get-ChildItem -Path $backupLocation -Filter "*_Full" | Sort-Object CreationTime
$lastFullBackup = $fullBackups | Select-Object -Last 1
if ($lastFullBackup -eq $null) {
    FullBackup
} else {
    $lastFullBackupTime = $lastFullBackup.CreationTime
    $daysSinceLastFullBackup = [math]::Round((Get-Date - $lastFullBackupTime).TotalDays)  # Calculate the days difference
    if ($daysSinceLastFullBackup -ge $backupFrequency) {
        FullBackup
        CleanUpBackups
    } else {
        DifferentialBackup
    }
}
