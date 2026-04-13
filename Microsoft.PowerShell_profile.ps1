# ==========================================
# PowerShell Hacker Edition (By Yasser-Fekry)
# Fixed & Optimized Version
# ==========================================

# 🧩 Enable Terminal Icons (if available)
if (Get-Module -ListAvailable -Name Terminal-Icons) {
    Import-Module Terminal-Icons -ErrorAction SilentlyContinue
}

# 🧠 PSReadline Settings
Set-PSReadlineOption -EditMode Windows
Set-PSReadlineOption -PredictionSource History
Set-PSReadlineOption -HistorySearchCursorMovesToEnd
Set-PSReadlineOption -BellStyle None

# 🎨 Oh My Posh Local Theme (only if installed & theme file exists)
$localTheme = "$HOME\Documents\PowerShell\cobalt2.omp.json"
if (Test-Path $localTheme -PathType Leaf) {
    if (Get-Command 'oh-my-posh' -ErrorAction SilentlyContinue) {
        oh-my-posh init pwsh --config $localTheme | Invoke-Expression
    } else {
        Write-Host "⚠️  Theme file found but 'oh-my-posh' not installed." -ForegroundColor Yellow
        Write-Host "➡️  Install oh-my-posh or remove the theme file to silence this message." -ForegroundColor DarkGray
    }
}

# =========================
# 🚀 Biso's Ra2e Aliases & Functions
# =========================

# ---- Quick Navigation ----
function Up-Dir { Set-Location .. }
Set-Alias -Name .. -Value Up-Dir -Option AllScope -Force
function GoHome { Set-Location $HOME }
Set-Alias -Name ~ -Value GoHome -Option AllScope -Force
Set-Alias -Name c -Value Set-Location -Option AllScope -Force
Set-Alias -Name h -Value GoHome -Option AllScope -Force

function desk { Set-Location "$HOME\Desktop" }
function docs { Set-Location "$HOME\Documents" }
function down { Set-Location "$HOME\Downloads" }

# ---- Pretty Listing ----
function Get-PrettyList {
    param($p='.')
    Get-ChildItem -LiteralPath $p -Force |
        Sort-Object @{Expression={$_.PSIsContainer};Descending=$true}, LastWriteTime
}

function Get-DetailedList {
    param($p='.')
    Get-ChildItem -LiteralPath $p -Force |
        Sort-Object @{Expression={$_.PSIsContainer};Descending=$true}, LastWriteTime |
        Format-Table Mode, @{N='Size';E={
            if ($_.PSIsContainer) {''}
            else {[math]::Round($_.Length/1KB,2).ToString() + ' KB'}
        }}, LastWriteTime, Name -AutoSize
}

Set-Alias -Name ls -Value Get-PrettyList -Option AllScope -Force
Set-Alias -Name ll -Value Get-DetailedList -Option AllScope -Force
Set-Alias -Name la -Value Get-PrettyList -Option AllScope -Force
Set-Alias -Name lsl -Value Get-DetailedList -Option AllScope -Force

# ---- Git Shortcuts (ra2e) ----
function Invoke-GitStatus { git status }
function Invoke-GitAdd { param($file) if ($file) { git add $file } else { git add . } }
function Invoke-GitCommit {
    param($m)
    if ($m) { git commit -m $m }
    else { git commit }
}
function Invoke-GitPush { git push }
function Invoke-GitPull { git pull }
function Invoke-GitCheckout {
    param($branch)
    if ($branch) { git checkout $branch }
    else { Write-Host "Usage: gco <branch>" -ForegroundColor Yellow }
}
function Invoke-GitClone {
    param($repo)
    if ($repo) { git clone $repo }
    else { Write-Host "Usage: gcl <repo-url>" -ForegroundColor Yellow }
}

Set-Alias -Name gst -Value Invoke-GitStatus -Option AllScope -Force
Set-Alias -Name ga -Value Invoke-GitAdd -Option AllScope -Force
Set-Alias -Name gc -Value Invoke-GitCommit -Option AllScope -Force
Set-Alias -Name gp -Value Invoke-GitPush -Option AllScope -Force
Set-Alias -Name gpl -Value Invoke-GitPull -Option AllScope -Force
Set-Alias -Name gco -Value Invoke-GitCheckout -Option AllScope -Force
Set-Alias -Name gcl -Value Invoke-GitClone -Option AllScope -Force

# ---- Edit / Profile ----
function Edit-Profile { notepad $PROFILE }
function Edit-File {
    param($f)
    if ($f) { notepad $f }
    else { notepad $PROFILE }
}

Set-Alias -Name e -Value Edit-Profile -Option AllScope -Force
Set-Alias -Name ep -Value Edit-Profile -Option AllScope -Force
Set-Alias -Name edit -Value Edit-File -Option AllScope -Force

# ---- Admin / Elevated ----
function Invoke-Sudo {
    param([string]$Command)
    if ($Command) {
        Start-Process powershell -Verb runAs -ArgumentList "-NoProfile -Command $Command"
    } else {
        Start-Process powershell -Verb runAs
    }
}

Set-Alias -Name sudo -Value Invoke-Sudo -Option AllScope -Force
Set-Alias -Name su -Value Invoke-Sudo -Option AllScope -Force
Set-Alias -Name admin -Value Invoke-Sudo -Option AllScope -Force

# ---- System Quickies ----
Set-Alias -Name cls -Value Clear-Host -Option AllScope -Force
function Invoke-Reboot { Restart-Computer }
function Invoke-Shutdown { Stop-Computer }

Set-Alias -Name reboot -Value Invoke-Reboot -Option AllScope -Force
Set-Alias -Name shutdown -Value Invoke-Shutdown -Option AllScope -Force

function Get-Memory {
    Get-CimInstance Win32_OperatingSystem |
        Select-Object @{N='FreeMB';E={[math]::Round($_.FreePhysicalMemory/1024,2)}},
                      @{N='TotalMB';E={[math]::Round($_.TotalVisibleMemorySize/1024,2)}}
}
Set-Alias -Name mem -Value Get-Memory -Option AllScope -Force

# ---- Network ----
function Get-IPAddresses {
    Write-Host "🌐 IPv4 Addresses:" -ForegroundColor Cyan
    Get-NetIPAddress | Where-Object { $_.AddressFamily -eq 'IPv4' } |
        Select-Object InterfaceAlias, IPAddress |
        Format-Table -AutoSize
}

function Get-AllIPAddresses {
    Write-Host "🌐 All Network Interfaces:" -ForegroundColor Cyan
    Get-NetIPAddress |
        Select-Object InterfaceAlias, AddressFamily, IPAddress, PrefixLength |
        Format-Table -AutoSize
}

Set-Alias -Name ips -Value Get-IPAddresses -Option AllScope -Force
Set-Alias -Name ip -Value Get-AllIPAddresses -Option AllScope -Force
Set-Alias -Name ipa -Value Get-AllIPAddresses -Option AllScope -Force

# ---- File Helpers ----
function New-DirectoryAndEnter {
    param($name)
    New-Item -ItemType Directory -Path $name -Force | Out-Null
    Set-Location $name
}
function New-FileQuick {
    param($name)
    New-Item -ItemType File -Path $name -Force
}
function Remove-ForceRecurse {
    param($p)
    Remove-Item $p -Recurse -Force
}
function Touch-File {
    param($name)
    if ($name) {
        if (Test-Path $name) {
            # Update timestamp if file exists
            (Get-Item $name).LastWriteTime = Get-Date
        } else {
            # Create new file if doesn't exist
            New-Item -ItemType File -Path $name -Force | Out-Null
        }
    } else {
        Write-Host "Usage: touch <filename>" -ForegroundColor Yellow
    }
}

Set-Alias -Name mk -Value New-DirectoryAndEnter -Option AllScope -Force
Set-Alias -Name nf -Value New-FileQuick -Option AllScope -Force
Set-Alias -Name rmf -Value Remove-ForceRecurse -Option AllScope -Force
Set-Alias -Name touch -Value Touch-File -Option AllScope -Force

# ---- Clipboard / Quick Copy ----
function Copy-ToClipboard {
    param($text)
    Set-Clipboard $text
    Write-Host "✅ Copied to clipboard" -ForegroundColor Green
}
Set-Alias -Name cpy -Value Copy-ToClipboard -Option AllScope -Force

# ---- Utilities ----
function Get-SystemInfo {
    Get-ComputerInfo | Select-Object CsName, OsName, OsArchitecture, OsVersion
}
function Get-CurrentLocation { Get-Location }

Set-Alias -Name sysinfo -Value Get-SystemInfo -Option AllScope -Force
Set-Alias -Name whereami -Value Get-CurrentLocation -Option AllScope -Force

# ---- Fancy Hacker Alias ----
function Show-HackerMode {
    Clear-Host
    Write-Host ""
    Write-Host "  ╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor DarkGreen
    Write-Host "  ║                { Help  List  - Command List }                 ║" -ForegroundColor Green
    Write-Host "  ╠═══════════════════════════════════════════════════════════════╣" -ForegroundColor DarkGreen
    Write-Host ""
    Write-Host "  📁 Navigation:" -ForegroundColor Cyan
    Write-Host "     desk          → Go to Desktop" -ForegroundColor White
    Write-Host "     docs          → Go to Documents" -ForegroundColor White
    Write-Host "     down          → Go to Downloads" -ForegroundColor White
    Write-Host "     ..            → Go up one directory" -ForegroundColor White
    Write-Host "     ~             → Go to Home" -ForegroundColor White
    Write-Host ""
    Write-Host "  📂 Files & Folders:" -ForegroundColor Cyan
    Write-Host "     ls / ll       → List files (detailed)" -ForegroundColor White
    Write-Host "     mk <name>     → Make directory & enter it" -ForegroundColor White
    Write-Host "     touch <file>  → Create/update file" -ForegroundColor White
    Write-Host "     rmf <path>    → Remove file/folder (force)" -ForegroundColor White
    Write-Host ""
    Write-Host "  🔧 Git Commands:" -ForegroundColor Cyan
    Write-Host "     gst           → Git status" -ForegroundColor White
    Write-Host "     ga <file>     → Git add" -ForegroundColor White
    Write-Host "     gc 'message'  → Git commit with message" -ForegroundColor White
    Write-Host "     gp            → Git push" -ForegroundColor White
    Write-Host "     gpl           → Git pull" -ForegroundColor White
    Write-Host "     gco <branch>  → Git checkout branch" -ForegroundColor White
    Write-Host ""
    Write-Host "  💻 System Info:" -ForegroundColor Cyan
    Write-Host "     ip / ipa      → Show all IP addresses" -ForegroundColor White
    Write-Host "     mem           → Show memory usage" -ForegroundColor White
    Write-Host "     sysinfo       → Show system information" -ForegroundColor White
    Write-Host "     whereami      → Show current location" -ForegroundColor White
    Write-Host ""
    Write-Host "  ⚡ Power Commands:" -ForegroundColor Cyan
    Write-Host "     sudo <cmd>    → Run command as Admin" -ForegroundColor White
    Write-Host "     edit <file>   → Edit file in notepad" -ForegroundColor White
    Write-Host "     cpy <text>    → Copy text to clipboard" -ForegroundColor White
    Write-Host ""
    Write-Host "  ╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor DarkGreen
    Write-Host ""
}
Set-Alias -Name help -Value Show-HackerMode -Option AllScope -Force

# =========================
# 💀 Startup Banner
# =========================
Clear-Host

# Quick boot animation
for ($i = 0; $i -lt 3; $i++) {
    Write-Host -NoNewline "Initializing" -ForegroundColor Green
    for ($j = 0; $j -lt ($i+1); $j++) { Write-Host -NoNewline "." -ForegroundColor Green }
    Start-Sleep -Milliseconds 140
    Write-Host ""
}
Start-Sleep -Milliseconds 80
Clear-Host

# ASCII Logo
Write-Host @"
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⢋⣠⣤⣤⣤⣤⣤⡙⠻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⠟⢁⣴⣿⣿⣿⣿⣿⣿⣿⣿⣦⣈⠻⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⡿⢠⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡆⢹⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⠈⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⡿⢀⣿⣿⡿⠿⠛⢋⣉⣉⡙⠛⠿⢿⣿⣿⡄⢹⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣧⠘⢿⣤⡄⢰⣿⣿⣿⣿⣿⣿⣶⠀⣤⣽⠃⣸⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⡿⠛⢋⣁⡈⢻⡇⢸⣿⣿⣿⣿⣿⣿⡿⢠⡿⢁⣈⡙⠛⢿⣿⣿⣿⣿
⣿⣿⣿⡿⢁⡾⠿⠿⠿⠄⠹⠄⠙⠛⠿⠿⠟⠋⠠⠞⠠⠾⠿⠿⠿⡄⢻⣿⣿⣿
⣿⣿⡿⢁⣾⠀⣶⣶⣿⣿⣶⣾⣶⣶⣶⣶⣶⣿⣿⣷⣾⣷⣶⣶⠀⣷⡀⢻⣿⣿
⣿⣿⠁⣼⣿⠀⣿⣿⣿⣿⣿⣿⠟⣉⣤⣤⣈⠛⣿⣿⣿⣿⣿⣿⠀⣿⣷⡈⢿⣿
⣿⠃⣼⣿⣿⠀⣿⣿⣿⣿⣿⡇⣰⡛⢿⡿⠛⣧⠘⣿⣿⣿⣿⣿⠀⣿⣿⣷⠈⣿
⡇⢸⣿⣿⣿⠀⣿⣿⣿⣿⣿⣧⡘⠻⣾⣷⠾⠋⣰⣿⣿⣿⣿⣿⠀⣿⣿⣿⣧⠘
⣷⣌⠙⠿⣿⠀⣿⣿⣿⣿⣿⣿⣿⣄⣉⣉⣠⣿⣿⣿⣿⣿⣿⣿⠀⣿⡿⠛⣡⣼
⣿⣿⣿⣦⣈⠀⠿⠿⠿⠿⠿⠟⠛⠛⠛⠛⠿⠛⠟⠛⢿⣿⠛⠻⠀⢉⣴⣾⣿⣿
⣿⣿⣿⣿⣿⡀⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠀⣿⣿⣿⣿⣿
"@ -ForegroundColor Green
Write-Host "( Secrecy is security, and security is victory ! )" -ForegroundColor Green
Write-Host "`n[𓋖] System Boot Complete —  Mode Activated..." -ForegroundColor Green
Write-Host ""
