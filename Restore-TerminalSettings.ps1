<#
.SYNOPSIS
    Restores custom Windows Terminal settings, PowerShell profile, oh-my-posh theme, and background image.

.DESCRIPTION
    This script will:
    1. Install oh-my-posh if not already installed
    2. Install the Hasklug Nerd Font automatically
    3. Copy the background image to Pictures folder
    4. Apply ONLY visual settings to Windows Terminal (preserves other config)
    5. Restore PowerShell profile
    6. Restore oh-my-posh custom theme

.NOTES
    Script will automatically elevate to Administrator if needed.
    Requires winget and PowerShell 7.5+
    Only applies visual theming - preserves existing terminal configuration.
#>

# Self-elevation check
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Restarting script with administrator privileges..." -ForegroundColor Yellow
    $originalUser = $env:USERNAME
    Start-Process pwsh -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -OriginalUser `"$originalUser`"" -Verb RunAs
    exit
}

# Get the correct user profile path
param([string]$OriginalUser)

if ($OriginalUser) {
    $TargetUserProfile = "C:\Users\$OriginalUser"
    $TargetPowerShellProfile = "$TargetUserProfile\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
} else {
    $TargetUserProfile = $env:USERPROFILE
    $TargetPowerShellProfile = $PROFILE
}

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
$BackgroundDir = "$TargetUserProfile\Pictures\Backgrounds"
if (!(Test-Path $BackgroundDir)) {
    New-Item -ItemType Directory -Path $BackgroundDir -Force | Out-Null
    Write-Host "   Created directory: $BackgroundDir" -ForegroundColor Green
}
Copy-Item "$BackupFolder\Console Background.png" "$BackgroundDir\Console Background.png" -Force
Write-Host "   Background image copied successfully." -ForegroundColor Green

# Restore Windows Terminal settings
Write-Host ""
Write-Host "[4/6] Applying Windows Terminal visual settings..." -ForegroundColor Yellow
$TerminalSettingsPath = "C:\Users\$(if($OriginalUser){$OriginalUser}else{$env:USERNAME})\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState"

# Check if Windows Terminal is installed
if (!(Test-Path (Split-Path $TerminalSettingsPath))) {
    Write-Host "   Windows Terminal not found. Installing via winget..." -ForegroundColor Yellow
    winget install Microsoft.WindowsTerminal --accept-source-agreements --accept-package-agreements
    Start-Sleep -Seconds 2
}

if (Test-Path "$TerminalSettingsPath\settings.json") {
    # Backup existing settings
    Copy-Item "$TerminalSettingsPath\settings.json" "$TerminalSettingsPath\settings.json.backup" -Force
    Write-Host "   Backed up existing settings to settings.json.backup" -ForegroundColor Cyan
    
    # Read existing settings
    $existingSettings = Get-Content "$TerminalSettingsPath\settings.json" -Raw | ConvertFrom-Json
    
    # Apply only visual settings to profiles.defaults
    if (!$existingSettings.profiles) {
        $existingSettings | Add-Member -MemberType NoteProperty -Name "profiles" -Value @{}
    }
    if (!$existingSettings.profiles.defaults) {
        $existingSettings.profiles | Add-Member -MemberType NoteProperty -Name "defaults" -Value @{}
    }
    
    # Apply visual settings
    $bgPath = "C:\Users\$(if($OriginalUser){$OriginalUser}else{$env:USERNAME})\Pictures\Backgrounds\Console Background.png"
    $existingSettings.profiles.defaults | Add-Member -MemberType NoteProperty -Name "backgroundImage" -Value $bgPath -Force
    $existingSettings.profiles.defaults | Add-Member -MemberType NoteProperty -Name "backgroundImageAlignment" -Value "bottomRight" -Force
    $existingSettings.profiles.defaults | Add-Member -MemberType NoteProperty -Name "backgroundImageOpacity" -Value 0.67 -Force
    $existingSettings.profiles.defaults | Add-Member -MemberType NoteProperty -Name "backgroundImageStretchMode" -Value "uniform" -Force
    $existingSettings.profiles.defaults | Add-Member -MemberType NoteProperty -Name "useAcrylic" -Value $true -Force
    $existingSettings.profiles.defaults | Add-Member -MemberType NoteProperty -Name "opacity" -Value 100 -Force
    
    if (!$existingSettings.profiles.defaults.font) {
        $existingSettings.profiles.defaults | Add-Member -MemberType NoteProperty -Name "font" -Value @{}
    }
    $existingSettings.profiles.defaults.font | Add-Member -MemberType NoteProperty -Name "face" -Value "Hasklug Nerd Font Mono" -Force
    
    # Save updated settings
    $existingSettings | ConvertTo-Json -Depth 100 | Set-Content "$TerminalSettingsPath\settings.json"
    Write-Host "   Visual settings applied to Windows Terminal." -ForegroundColor Green
} else {
    Write-Host "   ERROR: Could not locate Windows Terminal settings path." -ForegroundColor Red
}

# Restore PowerShell profile
Write-Host ""
Write-Host "[5/6] Restoring PowerShell profile..." -ForegroundColor Yellow
$ProfileDir = Split-Path $TargetPowerShellProfile -Parent
if (!(Test-Path $ProfileDir)) {
    New-Item -ItemType Directory -Path $ProfileDir -Force | Out-Null
    Write-Host "   Created directory: $ProfileDir" -ForegroundColor Green
}
if (Test-Path $TargetPowerShellProfile) {
    Copy-Item $TargetPowerShellProfile "$TargetPowerShellProfile.backup" -Force
    Write-Host "   Backed up existing profile to $TargetPowerShellProfile.backup" -ForegroundColor Cyan
}
Copy-Item "$BackupFolder\Microsoft.PowerShell_profile.ps1" $TargetPowerShellProfile -Force
Write-Host "   PowerShell profile restored." -ForegroundColor Green

# Restore oh-my-posh theme
Write-Host ""
Write-Host "[6/6] Restoring oh-my-posh theme..." -ForegroundColor Yellow
$ThemeDir = "$TargetUserProfile\.config\oh-my-posh"
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
