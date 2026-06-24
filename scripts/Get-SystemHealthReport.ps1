<#
.SYNOPSIS
    Produces a quick health report for a Windows machine (disk, memory, uptime, CPU, pending reboot).
.DESCRIPTION
    A fast first-look diagnostic for IT support. Prints a summary to the console and can optionally
    save an HTML report. Uses CIM so it works on the local machine or a reachable remote computer.
.PARAMETER ComputerName
    Target computer. Defaults to the local machine.
.PARAMETER ReportPath
    Optional path to save an HTML report, e.g. C:\Reports\health.html
.EXAMPLE
    .\Get-SystemHealthReport.ps1
.EXAMPLE
    .\Get-SystemHealthReport.ps1 -ComputerName PC01 -ReportPath .\health.html
.NOTES
    Author: Tegan Wilton
#>
[CmdletBinding()]
param(
    [string]$ComputerName = $env:COMPUTERNAME,
    [string]$ReportPath
)

# --- Collect data (CIM is the modern, reliable way) --------------------------
# Only pass -ComputerName for genuinely REMOTE targets. Using it locally forces the WinRM remoting
# path, which fails on a normal machine where WinRM isn't enabled — so we run locally by default.
$isRemote = $ComputerName -and $ComputerName -notin @($env:COMPUTERNAME, 'localhost', '.', '127.0.0.1')
$cimArgs  = @{}
if ($isRemote) { $cimArgs['ComputerName'] = $ComputerName }

$os    = Get-CimInstance Win32_OperatingSystem @cimArgs
$cpu   = Get-CimInstance Win32_Processor       @cimArgs | Select-Object -First 1
$disks = Get-CimInstance Win32_LogicalDisk     @cimArgs -Filter "DriveType=3"

$uptime     = (Get-Date) - $os.LastBootUpTime
$ramTotalGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 1)
$ramFreeGB  = [math]::Round($os.FreePhysicalMemory     / 1MB, 1)
$ramUsedPct = [math]::Round((($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) /
                              $os.TotalVisibleMemorySize) * 100, 0)

# Pending reboot is a common cause of odd behaviour — worth flagging
$pendingReboot = $false
foreach ($k in @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending',
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired'
)) { if (Test-Path $k) { $pendingReboot = $true } }

# --- Shape the output --------------------------------------------------------
$summary = [PSCustomObject]@{
    ComputerName  = $ComputerName
    OS            = $os.Caption
    LastBoot      = $os.LastBootUpTime
    UptimeHours   = [math]::Round($uptime.TotalHours, 1)
    CPULoadPct    = $cpu.LoadPercentage
    RAM_TotalGB   = $ramTotalGB
    RAM_FreeGB    = $ramFreeGB
    RAM_UsedPct   = $ramUsedPct
    PendingReboot = $pendingReboot
}

$diskReport = foreach ($d in $disks) {
    [PSCustomObject]@{
        Drive   = $d.DeviceID
        SizeGB  = [math]::Round($d.Size      / 1GB, 1)
        FreeGB  = [math]::Round($d.FreeSpace / 1GB, 1)
        FreePct = if ($d.Size) { [math]::Round(($d.FreeSpace / $d.Size) * 100, 0) } else { 0 }
    }
}

$procArgs = @{}
if ($isRemote) { $procArgs['ComputerName'] = $ComputerName }
$topProc = Get-Process @procArgs |
    Sort-Object WS -Descending | Select-Object -First 5 `
        Name, @{N='MemoryMB'; E={ [math]::Round($_.WS / 1MB, 0) }}

# --- Console report ----------------------------------------------------------
Write-Host "`n=== System Health: $ComputerName ===" -ForegroundColor Cyan
$summary | Format-List
Write-Host "Disks:" -ForegroundColor Cyan
$diskReport | Format-Table -AutoSize
Write-Host "Top processes by memory:" -ForegroundColor Cyan
$topProc | Format-Table -AutoSize

# Flag low disk space loudly
foreach ($d in $diskReport) {
    if ($d.FreePct -lt 15) {
        Write-Warning "Low disk space on $($d.Drive): $($d.FreePct)% free."
    }
}

# --- Optional HTML report ----------------------------------------------------
if ($ReportPath) {
    $html  = $summary    | ConvertTo-Html -As List -PreContent "<h1>System Health: $ComputerName</h1>" | Out-String
    $html += $diskReport | ConvertTo-Html -PreContent "<h2>Disks</h2>"          | Out-String
    $html += $topProc    | ConvertTo-Html -PreContent "<h2>Top Processes</h2>"  | Out-String
    $html | Out-File -FilePath $ReportPath -Encoding utf8
    Write-Host "HTML report saved to $ReportPath" -ForegroundColor Green
}
