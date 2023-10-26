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
        $lastFullBackupPath = $lastFullBackup.FullName
        $lastFullBackupTime = $lastFullBackup.CreationTime
        $diffBackupFolder = Join-Path -Path $backupLocation -ChildPath ((Get-Date -Format "yyyyMMdd_HHmmss") + "_Diff")
        New-Item -ItemType Directory -Path $diffBackupFolder -Force

        $sourceFiles = Get-ChildItem -Path $sourceDirectories -File -Recurse
        $lastFullBackupFiles = Get-ChildItem -Path $lastFullBackupPath -File -Recurse

        if ($sourceFiles -ne $null -and $lastFullBackupFiles -ne $null) {
            $sourceFileHash = @{}
            $lastFullBackupFileHash = @{}

            # Create a hash table of source files
            foreach ($file in $sourceFiles) {
                $relativePath = $file.FullName.Substring((Get-Item -Path $sourceDirectories[0]).FullName.Length)
                $sourceFileHash[$relativePath] = $file
            }

            # Create a hash table of last full backup files
            foreach ($file in $lastFullBackupFiles) {
                $relativePath = $file.FullName.Substring($lastFullBackupPath.Length)
                $lastFullBackupFileHash[$relativePath] = $file.LastWriteTime
            }

            foreach ($relativePath in $sourceFileHash.Keys) {
                if ($lastFullBackupFileHash.ContainsKey($relativePath)) {
                    $sourceFile = $sourceFileHash[$relativePath]
                    $lastModifiedTime = $sourceFile.LastWriteTime

                    # Compare the last modification time with the full backup time
                    if ($lastModifiedTime -gt $lastFullBackupTime) {
                        $destinationPath = Join-Path -Path $diffBackupFolder -ChildPath $relativePath
                        $destinationDirectory = [System.IO.Path]::GetDirectoryName($destinationPath)
                        if (-not (Test-Path -Path $destinationDirectory)) {
                            New-Item -ItemType Directory -Path $destinationDirectory -Force
                        }

                        Copy-Item -Path $sourceFile.FullName -Destination $destinationPath -ErrorAction Stop
                    }
                }
            }
        } else {
            Write-Host "Source files or last full backup files are null."
        }
    } else {
        Write-Host "No full backup found. Cannot perform a differential backup."
    }
}

# Check if it's time for a full backup or differential backup
$fullBackups = Get-ChildItem -Path $backupLocation -Filter "*_Full" | Sort-Object CreationTime
$lastFullBackup = $fullBackups | Select-Object -Last 1
if ($lastFullBackup -eq $null) {
    FullBackup
} else {
    $lastFullBackupTime = $lastFullBackup.CreationTime
    $currentDateTime = Get-Date
    $daysSinceLastFullBackup = [math]::Round(($currentDateTime - $lastFullBackupTime).TotalDays)

    if ($daysSinceLastFullBackup -ge $backupFrequency) {
        FullBackup
        CleanUpBackups
    } else {
        DifferentialBackup
    }
}
