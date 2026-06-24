# ⚙️ PowerShell IT Support Toolkit

A collection of practical PowerShell scripts I use to automate everyday IT support and system
administration tasks — health checks, reporting, inventory, cleanup and monitoring.

> The point of this repo: most first-line people do these jobs by hand. I script them — faster,
> consistent, and repeatable.

---

## 🎯 Skills demonstrated
`PowerShell` · `Automation` · `Active Directory` · `Reporting (HTML/CSV)` · `WMI/CIM` ·
`Windows administration` · `Scripting best practice (-WhatIf, comment-based help)`

---

## 📜 The scripts

| Script | What it does | Example |
|--------|--------------|---------|
| **Get-SystemHealthReport.ps1** | Disk, memory, uptime, CPU load, pending-reboot + top processes; console or HTML report. | `.\Get-SystemHealthReport.ps1 -ReportPath .\health.html` |
| **Get-ADPasswordExpiryReport.ps1** | Lists AD users whose passwords expire within N days (proactive helpdesk). | `.\Get-ADPasswordExpiryReport.ps1 -Days 7` |
| **Get-InstalledSoftwareInventory.ps1** | Inventories installed software from the registry → CSV (audits). | `.\Get-InstalledSoftwareInventory.ps1 -ExportPath .\software.csv` |
| **Clear-TempAndLogs.ps1** | Frees disk space — temp folders, old logs, recycle bin; reports GB reclaimed. | `.\Clear-TempAndLogs.ps1 -WhatIf` |
| **Test-Endpoints.ps1** | Ping + TCP-port + service checks against a list of hosts (mini health-check). | `.\Test-Endpoints.ps1 -CsvPath .\endpoints.csv` |

---

## 🛡️ Safe by design
- The four `Get-*`/`Test-*` scripts are **read-only** — they report, they don't change anything.
- `Clear-TempAndLogs.ps1` is the only one that deletes — it supports **`-WhatIf`** (preview first),
  only touches files **older than `-DaysOld`**, and reports exactly how much space it freed.
- Every script has **comment-based help**: run `Get-Help .\Script.ps1 -Full`.

---

## ▶️ How to run
```powershell
# Allow scripts for this session only (safe, resets when you close the window)
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

# Read the built-in help for any script
Get-Help .\scripts\Get-SystemHealthReport.ps1 -Full

# Run one
.\scripts\Get-SystemHealthReport.ps1
```
> The AD script needs the **ActiveDirectory** module (RSAT) and a domain — run it against your
> [AD Home Lab](../ad-home-lab).

---

## 📸 Screenshots
> _Add a couple of output screenshots into `docs/screenshots/` — e.g. the health report and the
> password-expiry table._

## ▶️ Publish to GitHub
```bash
cd powershell-toolkit
git init && git add . && git commit -m "PowerShell IT support toolkit"
git branch -M main
git remote add origin https://github.com/<your-username>/powershell-toolkit.git
git push -u origin main
```
Pin it on GitHub and add it to LinkedIn → **Featured**.
