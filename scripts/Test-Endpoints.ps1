<#
.SYNOPSIS
    Checks a list of endpoints for reachability (ping), an open TCP port, and an optional service.
.DESCRIPTION
    A lightweight monitoring / health-check helper. Reads a CSV of targets and reports the status of
    each, so you can quickly confirm "are the key systems up?". Pairs well with the AD Home Lab.
.PARAMETER CsvPath
    CSV with columns: Name, Host, Port (optional), ServiceName (optional — checked on the local box).
.PARAMETER ExportPath
    Optional CSV path for the results.
.EXAMPLE
    .\Test-Endpoints.ps1 -CsvPath .\endpoints.csv
.NOTES
    Author: Tegan Wilton
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateScript({ Test-Path $_ })]
    [string]$CsvPath,
    [string]$ExportPath
)

$targets = Import-Csv $CsvPath

$results = foreach ($t in $targets) {
    $ping = Test-Connection -ComputerName $t.Host -Count 1 -Quiet -ErrorAction SilentlyContinue

    $portOpen = $null
    if ($t.Port) {
        $portOpen = (Test-NetConnection -ComputerName $t.Host -Port $t.Port `
                        -WarningAction SilentlyContinue).TcpTestSucceeded
    }

    $svcStatus = $null
    if ($t.ServiceName) {
        $svc = Get-Service -Name $t.ServiceName -ErrorAction SilentlyContinue
        $svcStatus = if ($svc) { $svc.Status } else { 'NotFound' }
    }

    [PSCustomObject]@{
        Name      = $t.Name
        Host      = $t.Host
        Ping      = if ($ping) { 'OK' } else { 'FAIL' }
        Port      = $t.Port
        PortOpen  = switch ($portOpen) { $true { 'OK' } $false { 'FAIL' } default { '-' } }
        Service   = $t.ServiceName
        SvcStatus = if ($svcStatus) { $svcStatus } else { '-' }
    }
}

$results | Format-Table -AutoSize
if ($ExportPath) {
    $results | Export-Csv -Path $ExportPath -NoTypeInformation
    Write-Host "Saved to $ExportPath" -ForegroundColor Green
}
