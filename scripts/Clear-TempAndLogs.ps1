<#
.SYNOPSIS
    Frees disk space by clearing temp folders, old log files and the recycle bin.
.DESCRIPTION
    A safe cleanup helper for the classic "my disk is full" ticket. Only deletes files last modified
    more than -DaysOld days ago, supports -WhatIf so you can preview every deletion, and reports how
    much space was reclaimed.
.PARAMETER DaysOld
    Only remove files older than this many days (default 7).
.PARAMETER LogPath
    Optional extra folder of logs to clean.
.EXAMPLE
    .\Clear-TempAndLogs.ps1 -WhatIf
.EXAMPLE
    .\Clear-TempAndLogs.ps1 -DaysOld 14
.NOTES
    Author: Tegan Wilton · Run as Administrator to clean C:\Windows\Temp.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [int]$DaysOld = 7,
    [string]$LogPath
)

function Get-FreeGB {
    $c = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
    [math]::Round($c.FreeSpace / 1GB, 2)
}

$before = Get-FreeGB
$cutoff = (Get-Date).AddDays(-$DaysOld)

$targets = @("$env:TEMP", "C:\Windows\Temp")
if ($LogPath) { $targets += $LogPath }

foreach ($folder in $targets) {
    if (-not (Test-Path $folder)) { continue }
    Write-Verbose "Cleaning $folder (files older than $DaysOld days)"
    Get-ChildItem -Path $folder -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object { $_.LastWriteTime -lt $cutoff } |
        ForEach-Object {
            if ($PSCmdlet.ShouldProcess($_.FullName, 'Delete')) {
                Remove-Item $_.FullName -Force -ErrorAction SilentlyContinue
            }
        }
}

if ($PSCmdlet.ShouldProcess('Recycle Bin', 'Empty')) {
    Clear-RecycleBin -Force -ErrorAction SilentlyContinue
}

$after = Get-FreeGB
Write-Host ("Free space: {0} GB -> {1} GB  (reclaimed {2} GB)" -f `
    $before, $after, [math]::Round($after - $before, 2)) -ForegroundColor Green
