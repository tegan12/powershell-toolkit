<#
.SYNOPSIS
    Lists enabled AD users whose passwords expire within a given number of days.
.DESCRIPTION
    A proactive helpdesk task: warn people before their password expires (and the support calls
    start). Uses the computed expiry attribute, so it respects the domain and any fine-grained
    password policies.
.PARAMETER Days
    Look-ahead window in days (default 14).
.PARAMETER SearchBase
    Optional OU distinguished name to limit the search, e.g. "OU=Sales,DC=corp,DC=local".
.PARAMETER ExportPath
    Optional CSV path for the results.
.EXAMPLE
    .\Get-ADPasswordExpiryReport.ps1 -Days 7
.EXAMPLE
    .\Get-ADPasswordExpiryReport.ps1 -Days 30 -ExportPath .\expiring.csv
.NOTES
    Author: Tegan Wilton · Requires the ActiveDirectory module (RSAT) and a domain.
#>
[CmdletBinding()]
param(
    [int]$Days = 14,
    [string]$SearchBase,
    [string]$ExportPath
)

Import-Module ActiveDirectory -ErrorAction Stop

$query = @{
    Filter     = "Enabled -eq 'True' -and PasswordNeverExpires -eq 'False'"
    Properties = 'DisplayName', 'msDS-UserPasswordExpiryTimeComputed'
}
if ($SearchBase) { $query['SearchBase'] = $SearchBase }

$cutoff = (Get-Date).AddDays($Days)

$report = Get-ADUser @query | ForEach-Object {
    $raw = $_.'msDS-UserPasswordExpiryTimeComputed'
    # 0 = must change now; very large = never — skip those edge values
    if ($raw -and $raw -ne 0 -and $raw -lt [Int64]::MaxValue) {
        $expiry = [datetime]::FromFileTime($raw)
        if ($expiry -le $cutoff) {
            [PSCustomObject]@{
                Name       = $_.DisplayName
                SamAccount = $_.SamAccountName
                Expires    = $expiry
                DaysLeft   = [math]::Round(($expiry - (Get-Date)).TotalDays, 1)
            }
        }
    }
} | Sort-Object DaysLeft

if (-not $report) {
    Write-Host "No passwords expiring within $Days days." -ForegroundColor Green
    return
}

$report | Format-Table -AutoSize
if ($ExportPath) {
    $report | Export-Csv -Path $ExportPath -NoTypeInformation
    Write-Host "Saved to $ExportPath" -ForegroundColor Green
}
