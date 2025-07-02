<#
  ============================================================================
  Microsoft ADMX Central Store Update Script - ADMX + ADML Sync & Backup
  ============================================================================
  Description : Safely backs up and updates the Group Policy Central Store
                with newer Windows ADMX and ADML files using timestamped backups.
  Target Use  : Windows Server domain controllers managing Group Policy for
                Windows 10/11 environments. Supports manual or automated sync.
  Key Features:
    - Backs up existing ADMX and ADML files into a dated folder
    - Compares file modification dates to avoid unnecessary overwrites
    - Logs all updated, skipped, and failed file operations
    - Outputs results to console and a .txt log file

  How to Use:
    1. Download the latest ADMX templates from Microsoft's official site:
       https://www.microsoft.com/en-us/download/details.aspx?id=104003
    2. Extract the templates to a working folder (e.g., C:\Temp\Windows_ADMX)
       Ensure structure includes:
         - .ADMX files in root (e.g., C:\Temp\Windows_ADMX\*.admx)
         - Language subfolder (e.g., C:\Temp\Windows_ADMX\en-US\*.adml)
    3. Update the #Configuration section to ensure directories and targets are correct
    4. Run this script from an RDP session on the domain controller using
       PowerShell **as Administrator**
    5. The script will:
       - Back up existing ADMX/ADML files from \\<domain>\SYSVOL\...\PolicyDefinitions
       - Copy only newer files from your extracted folder into the Central Store
       - Generate a detailed log file of changes

  Attribution :
    - Script developed with assistance from OpenAI ChatGPT
    - Reviewed and adapted for secure domain controller use

  License     : This script is licensed under the GNU General Public License v3.0
                You may freely use, modify, and redistribute with attribution.
                See: https://www.gnu.org/licenses/gpl-3.0.en.html

  Compatible OS:
    - Windows Server 2016, 2019, 2022 (Domain Controllers)
    - Supports clients running Windows 10 and Windows 11

  ============================================================================
#>

# CONFIGURATION
$domain = (Get-ADDomain).DNSRoot
$centralStore = "\\$domain\SYSVOL\$domain\Policies\PolicyDefinitions"
$timestamp = Get-Date -Format 'yyyy-MM-dd_HHmm'
$backupPath = "C:\ADMX_Backup\$timestamp"
$newAdmxSource = "C:\Temp\Windows_ADMX"  # Set to your extracted ADMX source
$languageCode = "en-US"
$logFilePath = "C:\ADMX_Backup\ADMX_UpdateLog_$timestamp.txt"

# Create backup folders
New-Item -ItemType Directory -Path "$backupPath\$languageCode" -Force | Out-Null

# Backup existing ADMX/ADML files
Write-Host "Creating backup at $backupPath..."
try {
    Copy-Item "$centralStore\*.admx" -Destination "$backupPath" -Recurse -Force -ErrorAction Stop
    Copy-Item "$centralStore\$languageCode\*.adml" -Destination "$backupPath\$languageCode" -Recurse -Force -ErrorAction Stop
    Write-Host "Backup complete.`n"
} catch {
    Write-Host "Error during backup: $_"
}

# Initialize log lists
$updatedFiles = @()
$errorLog = @()
$warningLog = @()

# COPY NEWER ADMX FILES
Write-Host "Copying newer ADMX files..."
Get-ChildItem -Path "$newAdmxSource\*.admx" | ForEach-Object {
    try {
        $destFile = Join-Path $centralStore $_.Name
        if (!(Test-Path $destFile) -or ($_.LastWriteTime -gt (Get-Item $destFile).LastWriteTime)) {
            Copy-Item $_.FullName -Destination $destFile -Force -ErrorAction Stop
            $updatedFiles += "ADMX: $($_.Name)"
        }
    } catch {
        $errorLog += "ADMX ERROR: $($_.Name) $_"
    }
}

# COPY NEWER ADML FILES
Write-Host "`nCopying newer ADML files..."
$sourceLangPath = Join-Path $newAdmxSource $languageCode
$destLangPath = Join-Path $centralStore $languageCode

Get-ChildItem -Path "$sourceLangPath\*.adml" | ForEach-Object {
    try {
        $destFile = Join-Path $destLangPath $_.Name
        if (!(Test-Path $destFile) -or ($_.LastWriteTime -gt (Get-Item $destFile).LastWriteTime)) {
            Copy-Item $_.FullName -Destination $destFile -Force -ErrorAction Stop
            $updatedFiles += "ADML: $($_.Name)"
        }
    } catch {
        $errorLog += "ADML ERROR: $($_.Name) $_"
    }
}

# Prepare full log
if ($updatedFiles.Count -eq 0) {
    $updatedFiles += "No files were updated. All files were already up to date."
}

$logOutput = @()
$logOutput += "===== ADMX/ADML Update Summary ($timestamp) ====="
$logOutput += ""
$logOutput += $updatedFiles
$logOutput += ""
if ($errorLog.Count -gt 0) {
    $logOutput += "===== ERRORS ====="
    $logOutput += $errorLog
}
if ($warningLog.Count -gt 0) {
    $logOutput += "===== WARNINGS ====="
    $logOutput += $warningLog
}

# Output to screen
$logOutput | ForEach-Object { Write-Host $_ }

# Write to file
$logOutput | Out-File -FilePath $logFilePath -Encoding UTF8
Write-Host "`nLog written to: $logFilePath"