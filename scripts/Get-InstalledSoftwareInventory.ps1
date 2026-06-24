<#
.SYNOPSIS
    Inventories installed software from the Windows registry (64- and 32-bit).
.DESCRIPTION
    Reads the uninstall registry keys — faster and more reliable than Win32_Product — and lists
    installed applications with version, publisher and install date. Handy for audits and for
    answering "what's actually installed on this machine?".
.PARAMETER ExportPath
    Optional CSV path for the inventory.
.EXAMPLE
    .\Get-InstalledSoftwareInventory.ps1
.EXAMPLE
    .\Get-InstalledSoftwareInventory.ps1 -ExportPath .\software.csv
.NOTES
    Author: Tegan Wilton
#>
[CmdletBinding()]
param(
    [string]$ExportPath
)

$registryPaths = @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
)

$software = Get-ItemProperty $registryPaths -ErrorAction SilentlyContinue |
    Where-Object { $_.DisplayName } |
    Select-Object @{N='Name';        E={ $_.DisplayName }},
                  @{N='Version';     E={ $_.DisplayVersion }},
                  @{N='Publisher';   E={ $_.Publisher }},
                  @{N='InstallDate'; E={ $_.InstallDate }} |
    Sort-Object Name -Unique

Write-Host "Found $($software.Count) installed applications." -ForegroundColor Cyan
$software | Format-Table -AutoSize

if ($ExportPath) {
    $software | Export-Csv -Path $ExportPath -NoTypeInformation
    Write-Host "Saved to $ExportPath" -ForegroundColor Green
}
