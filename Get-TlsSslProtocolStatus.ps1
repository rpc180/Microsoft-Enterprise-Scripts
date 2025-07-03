<#
  ============================================================================
  Windows TLS Protocol Status Checker - SCHANNEL Protocol Registry Scanner
  ============================================================================
  Description : Audits SCHANNEL protocol registry settings on the local system
                to determine whether SSL/TLS versions are enabled or disabled
                for both client and server roles.
  Target Use  : Windows Server and Windows Client systems where protocol-level
                hardening is required (e.g., PCI-DSS, FIPS 140-2 compliance).
  Key Features:
    - Enumerates all SCHANNEL protocol registry paths under:
        HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\SecurityProviders\
    - Reports status of SSL 2.0, SSL 3.0, TLS 1.0, 1.1, 1.2, and 1.3
    - Displays whether 'Enabled' DWORDs exist and their values
    - Flags missing keys or default behaviors
  
  Attribution :
    - Script developed and maintained by Romel Punsal
    - This script was developed with assistance from AI (OpenAI ChatGPT)
  
  License : 
    Copyright (c) 2024 Romel Punsal
    This script is provided under the GNU General Public License v3.0
    You may freely use, modify, and redistribute with attribution.
    This script is distributed WITHOUT ANY WARRANTY; without even the 
    implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR 
    PURPOSE.

  Compatible OS:
    - Windows Server 2012 R2, 2016, 2019, 2022
    - Windows 10 / 11 Professional or Enterprise Editions
  ============================================================================
#>

$tlsProtocols = @("SSL 2.0", "SSL 3.0", "TLS 1.0", "TLS 1.1", "TLS 1.2", "TLS 1.3")

foreach ($protocol in $tlsProtocols) {
    Write-Host "`nChecking $protocol..."
    foreach ($role in @("Client", "Server")) {
        $path = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\$protocol\$role"
        if (Test-Path $path) {
            $enabled = Get-ItemProperty -Path $path -Name Enabled -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Enabled -ErrorAction SilentlyContinue
            if ($null -ne $enabled) {
                Write-Host "  $role Enabled: $enabled"
            } else {
                Write-Host "  $role Enabled: (not defined)"
            }
        } else {
            Write-Host "  $role key not present"
        }
    }
}