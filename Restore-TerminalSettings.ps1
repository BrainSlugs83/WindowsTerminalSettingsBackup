#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Restores custom Windows Terminal settings, PowerShell profile, oh-my-posh theme, and background image.

.DESCRIPTION
    This script will:
    1. Install oh-my-posh if not already installed
    2. Install the Hasklug Nerd Font automatically
    3. Copy the background image to Pictures folder
    4. Restore Windows Terminal settings
    5. Restore PowerShell profile
    6. Restore oh-my-posh custom theme

.NOTES
    Run this script as Administrator.
    Requires winget and PowerShell 7.5+
#>

Write-Host "====================================" -ForegroundColor Cyan
Write-Host "Terminal Settings Restoration Script" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""

$BackupFolder = $PSScriptRoot

# Check if oh-my-posh is installed
Write-Host "[1/6] Checking oh-my-posh installation..." -ForegroundColor Yellow
if (!(Get-Command oh-my-posh -ErrorAction SilentlyContinue)) {
    Write-Host "   oh-my-posh not found. Installing via winget..." -ForegroundColor Yellow
    winget install JanDeDobbeleer.OhMyPosh -s winget --accept-source-agreements --accept-package-agreements
    
    # Refresh PATH environment variable
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    
    # Verify installation
    if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
        Write-Host "   oh-my-posh installed successfully." -ForegroundColor Green
    } else {
        Write-Host "   ERROR: oh-my-posh installation failed. Please restart PowerShell and try again." -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "   oh-my-posh is already installed." -ForegroundColor Green
}

# Install Nerd Font using oh-my-posh
Write-Host ""
Write-Host "[2/6] Installing Hasklug Nerd Font..." -ForegroundColor Yellow
# Check if font is already installed
$fontsInstalled = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" -ErrorAction SilentlyContinue | Get-Member -MemberType NoteProperty | Where-Object { $_.Name -like "*Hasklug*" -or $_.Name -like "*Hasklig*" }
if ($fontsInstalled) {
    Write-Host "   Hasklug Nerd Font is already installed." -ForegroundColor Green
} else {
    Write-Host "   Installing Hasklug Nerd Font..." -ForegroundColor Yellow
    oh-my-posh font install Hasklug
    Write-Host "   Font installation complete." -ForegroundColor Green
}

# Create background image directory
Write-Host ""
Write-Host "[3/6] Copying background image..." -ForegroundColor Yellow
$BackgroundDir = "$env:USERPROFILE\Pictures\Backgrounds-1080p"
if (!(Test-Path $BackgroundDir)) {
    New-Item -ItemType Directory -Path $BackgroundDir -Force | Out-Null
    Write-Host "   Created directory: $BackgroundDir" -ForegroundColor Green
}
Copy-Item "$BackupFolder\wallpaper-60247.jpg" "$BackgroundDir\wallpaper-60247.jpg" -Force
Write-Host "   Background image copied successfully." -ForegroundColor Green

# Restore Windows Terminal settings
Write-Host ""
Write-Host "[4/6] Restoring Windows Terminal settings..." -ForegroundColor Yellow
$TerminalSettingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState"

# Check if Windows Terminal is installed
if (!(Test-Path "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe")) {
    Write-Host "   Windows Terminal not found. Installing via winget..." -ForegroundColor Yellow
    winget install Microsoft.WindowsTerminal --accept-source-agreements --accept-package-agreements
    Start-Sleep -Seconds 2
}

if (Test-Path $TerminalSettingsPath) {
    # Backup existing settings
    if (Test-Path "$TerminalSettingsPath\settings.json") {
        Copy-Item "$TerminalSettingsPath\settings.json" "$TerminalSettingsPath\settings.json.backup" -Force
        Write-Host "   Backed up existing settings to settings.json.backup" -ForegroundColor Cyan
    }
    Copy-Item "$BackupFolder\settings.json" "$TerminalSettingsPath\settings.json" -Force
    Write-Host "   Windows Terminal settings restored." -ForegroundColor Green
} else {
    Write-Host "   ERROR: Could not locate Windows Terminal settings path." -ForegroundColor Red
}

# Restore PowerShell profile
Write-Host ""
Write-Host "[5/6] Restoring PowerShell profile..." -ForegroundColor Yellow
$ProfileDir = Split-Path $PROFILE -Parent
if (!(Test-Path $ProfileDir)) {
    New-Item -ItemType Directory -Path $ProfileDir -Force | Out-Null
    Write-Host "   Created directory: $ProfileDir" -ForegroundColor Green
}
if (Test-Path $PROFILE) {
    Copy-Item $PROFILE "$PROFILE.backup" -Force
    Write-Host "   Backed up existing profile to $PROFILE.backup" -ForegroundColor Cyan
}
Copy-Item "$BackupFolder\Microsoft.PowerShell_profile.ps1" $PROFILE -Force
Write-Host "   PowerShell profile restored." -ForegroundColor Green

# Restore oh-my-posh theme
Write-Host ""
Write-Host "[6/6] Restoring oh-my-posh theme..." -ForegroundColor Yellow
$ThemeDir = "$env:USERPROFILE\.config\oh-my-posh"
if (!(Test-Path $ThemeDir)) {
    New-Item -ItemType Directory -Path $ThemeDir -Force | Out-Null
    Write-Host "   Created directory: $ThemeDir" -ForegroundColor Green
}
Copy-Item "$BackupFolder\capr4n.json" "$ThemeDir\capr4n.json" -Force
Write-Host "   oh-my-posh theme restored." -ForegroundColor Green

# Summary
Write-Host ""
Write-Host "====================================" -ForegroundColor Cyan
Write-Host "Restoration Complete!" -ForegroundColor Green
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Close and reopen Windows Terminal" -ForegroundColor White
Write-Host "2. Your custom theme should now be active!" -ForegroundColor White
Write-Host ""
Write-Host "If you see weird characters, make sure 'Hasklug Nerd Font Mono' is installed." -ForegroundColor Cyan
