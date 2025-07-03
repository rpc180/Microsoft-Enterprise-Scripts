<#
  ============================================================================
  Install-RsatFeatureSubset - Dynamic RSAT Capability Installer for Windows
  ============================================================================
  Description : Provides an interactive interface for installing selected
                Remote Server Administration Tools (RSAT) features on Windows.
                Automatically discovers available RSAT features and supports
                selective or full installation.

  Target Use  : IT administrators deploying management tools on client systems
                such as Windows 10/11 Pro or Enterprise for Active Directory,
                DNS, DHCP, BitLocker, and more.

  Key Features:
    - Dynamically enumerates all RSAT capabilities available for the OS
    - Presents indexed list of tools with installation status
    - Allows interactive selection by index or bulk install via 'all'
    - Installs selected capabilities via Add-WindowsCapability
    - Logs installation results and errors to a timestamped log file

  Execution Instructions:
    1. Launch an elevated PowerShell session (Run as Administrator)
    2. Run the script:
         `.\Install-RsatFeatureSubset.ps1`
    3. Review the numbered list of RSAT tools shown
    4. When prompted, you can:
         - Enter comma-separated indexes (e.g., `0,2,4`) to install specific tools
         - Enter `all` (without quotes) to install every available RSAT capability
    5. A summary of installed and failed tools will be displayed and logged

  Attribution :
    - Script developed and maintained by Romel Punsal
    - This script was developed with assistance from AI (OpenAI ChatGPT)

  License :
    Copyright (c) 2024 Romel Punsal
    This script is provided under the GNU General Public License v3.0
    You may freely use, modify, and redistribute with attribution.
    This script is distributed WITHOUT ANY WARRANTY; without even the
    implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

  Compatible OS:
    - Windows 10 / 11 Professional or Enterprise Editions
    - Windows Server 2019 / 2022 (Desktop Experience) with on-demand capabilities
  ============================================================================
#>

# Log path for installation errors
$logPath = "$PSScriptRoot\RsatInstaller_ErrorLog.txt"
$installed = @()
$failed = @()

# Retrieve all RSAT-related capabilities from current OS
$rsatCapabilities = Get-WindowsCapability -Online | Where-Object { $_.Name -like "RSAT*" }

if (-not $rsatCapabilities) {
    Write-Error "No RSAT features were found. Make sure you are running on a supported Windows edition (e.g., Pro or Enterprise)."
    exit 1
}

# Display numbered menu
Write-Host "`nAvailable RSAT Tools:`n"
$rsatCapabilities = $rsatCapabilities | Sort-Object -Property Name
for ($i = 0; $i -lt $rsatCapabilities.Count; $i++) {
    $status = if ($rsatCapabilities[$i].State -eq "Installed") { "(Installed)" } else { "" }
    if ($status) {
        Write-Host " [$i] $($rsatCapabilities[$i].Name) $status" -ForegroundColor Green
    } else {
    Write-Host " [$i] $($rsatCapabilities[$i].Name) $status"
    }
}

# Prompt for selection
$userInput = Read-Host "`nEnter the numbers of the RSAT tools to install (comma-separated, e.g., 0,1,3) or type 'all' to install everything"

# Selection Phase
if ($userInput.Trim().ToLower() -eq 'all') {
    $selectedCapabilities = $rsatCapabilities
} else {
    $selections = $userInput -split "," | ForEach-Object { $_.Trim() } | Where-Object { $_ -match '^\d+$' }
    $selectedCapabilities = @()

    foreach ($index in $selections) {
        $i = [int]$index
        if ($i -ge 0 -and $i -lt $rsatCapabilities.Count) {
            $selectedCapabilities += $rsatCapabilities[$i]
        } else {
            Write-Warning "Invalid selection: $index"
        }
    }
}

# Installation Phase (shared by both branches)
foreach ($capability in $selectedCapabilities) {
    Write-Host "Installing: $($capability.Name)..."

    if ($capability.State -eq "Installed") {
        Write-Host "  Already installed: $($capability.Name)" -ForegroundColor Yellow
        $installed += "$($capability.Name) (Already Installed)"
        continue
    }

    try {
        Add-WindowsCapability -Online -Name $capability.Name -ErrorAction Stop
        Write-Host "  Success!" -ForegroundColor Green
        $installed += $capability.Name
    } catch {
        Write-Warning "  Failed to install $($capability.Name): $_"
        $failed += $capability.Name
        Add-Content -Path $logPath -Value "$(Get-Date -Format s) ERROR installing $($capability.Name): $_"
    }
}


# Summary
Write-Host "`n=== Installation Summary ==="
Write-Host "Installed: $($installed.Count)"
$installed | ForEach-Object { Write-Host " [+] $_" }

if ($failed.Count -gt 0) {
    Write-Host "`nFailed: $($failed.Count)" -ForegroundColor Red
    $failed | ForEach-Object { Write-Host " [-] $_" -ForegroundColor Red }
    Write-Host "`nErrors logged to: $logPath"
} else {
    Write-Host "`nAll selected features installed successfully!" -ForegroundColor Green
}