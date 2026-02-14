<#
.SYNOPSIS
    Restores custom Windows Terminal settings, PowerShell profile, oh-my-posh theme, Open Shell settings, and UAC configuration.

.DESCRIPTION
    This script provides a menu to restore:
    1. Terminal Settings (background, font, oh-my-posh theme, PowerShell profile)
    2. Open Shell Start Menu Settings
    4. UAC Settings (disable admin prompts)
    7. All of the above (default)

.NOTES
    Script will automatically elevate to Administrator if needed.
    Requires winget and PowerShell 7.5+
    Uses bitwise selection (e.g., 3 = 1+2, 5 = 1+4, 6 = 2+4, 7 = all)
#>

param([string]$OriginalUser, [int]$Selection)

# Self-elevation check
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Restarting script with administrator privileges..." -ForegroundColor Yellow
    $originalUser = $env:USERNAME
    $args = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -OriginalUser `"$originalUser`""
    if ($Selection) {
        $args += " -Selection $Selection"
    }
    Start-Process pwsh -ArgumentList $args -Verb RunAs
    exit
}

# Get the correct user profile path
if ($OriginalUser) {
    $TargetUserProfile = "C:\Users\$OriginalUser"
    $TargetPowerShellProfile = "$TargetUserProfile\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
} else {
    $TargetUserProfile = $env:USERPROFILE
    $TargetPowerShellProfile = $PROFILE
}

Write-Host "====================================" -ForegroundColor Cyan
Write-Host "  System Settings Restoration Tool  " -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""

# Show menu if no selection provided
if (-not $Selection) {
    Write-Host "Select what to restore (bitwise options):" -ForegroundColor Yellow
    Write-Host "  1 - Terminal Settings (background, font, oh-my-posh)" -ForegroundColor White
    Write-Host "  2 - Open Shell Start Menu Settings" -ForegroundColor White
    Write-Host "  4 - UAC Settings (disable admin prompts)" -ForegroundColor White
    Write-Host "  7 - All of the above (default)" -ForegroundColor Green
    Write-Host ""
    Write-Host "Examples: 3 = 1+2, 5 = 1+4, 6 = 2+4" -ForegroundColor DarkGray
    Write-Host ""
    $input = Read-Host "Enter selection [7]"
    if ([string]::IsNullOrWhiteSpace($input)) {
        $Selection = 7
    } else {
        $Selection = [int]$input
    }
}

Write-Host ""
Write-Host "Selected options: $Selection" -ForegroundColor Cyan
Write-Host ""

# Validate selection (must be between 1-7)
if ($Selection -lt 1 -or $Selection -gt 7) {
    Write-Host "Invalid selection. Must be between 1 and 7." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit
}

$BackupFolder = $PSScriptRoot

# ============================================
# OPTION 1: Terminal Settings
# ============================================
if ($Selection -band 1) {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host " Restoring Terminal Settings" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""

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
        
        # Set theme to follow system (dark/light mode)
        $existingSettings | Add-Member -MemberType NoteProperty -Name "theme" -Value "system" -Force
        
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
}

# ============================================
# OPTION 2: Open Shell Settings
# ============================================
if ($Selection -band 2) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host " Restoring Open Shell Settings" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""

    # Check if Open Shell is installed
    if (!(Test-Path "C:\Program Files\Open-Shell")) {
        Write-Host "Open Shell not found. Installing via winget..." -ForegroundColor Yellow
        winget install Open-Shell.Open-Shell-Menu --accept-source-agreements --accept-package-agreements
        Start-Sleep -Seconds 2
    } else {
        Write-Host "Open Shell is already installed." -ForegroundColor Green
    }

    # Import registry settings
    Write-Host ""
    Write-Host "Importing Open Shell registry settings..." -ForegroundColor Yellow
    if (Test-Path "$BackupFolder\OpenShell-Settings.reg") {
        reg import "$BackupFolder\OpenShell-Settings.reg" 2>$null
        Write-Host "   Registry settings imported." -ForegroundColor Green
    } else {
        Write-Host "   WARNING: OpenShell-Settings.reg not found." -ForegroundColor Yellow
    }

    # Restore custom start button images
    Write-Host ""
    Write-Host "Restoring custom start button images..." -ForegroundColor Yellow
    $ImagesSource = "$BackupFolder\OpenShell-Images"
    $ImagesDest = "$TargetUserProfile\Pictures\OpenShell"
    
    if (Test-Path $ImagesSource) {
        if (!(Test-Path $ImagesDest)) {
            New-Item -ItemType Directory -Path $ImagesDest -Force | Out-Null
        }
        Copy-Item "$ImagesSource\*" $ImagesDest -Recurse -Force
        Write-Host "   Custom start button images restored to $ImagesDest" -ForegroundColor Green
        
        # Update registry to point to new image location
        $newImagePath = "$ImagesDest\TrueOrb64.png"
        Set-ItemProperty -Path "HKCU:\Software\OpenShell\StartMenu\Settings" -Name "StartButtonPath" -Value $newImagePath -ErrorAction SilentlyContinue
        Write-Host "   Updated start button path to $newImagePath" -ForegroundColor Green
    } else {
        Write-Host "   WARNING: OpenShell-Images folder not found." -ForegroundColor Yellow
    }
}

# ============================================
# OPTION 4: UAC Settings
# ============================================
if ($Selection -band 4) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host " Configuring UAC Settings" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""

    Write-Host "Disabling UAC prompts for administrators..." -ForegroundColor Yellow
    $uacSetting = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name ConsentPromptBehaviorAdmin -ErrorAction SilentlyContinue
    if ($uacSetting.ConsentPromptBehaviorAdmin -ne 0) {
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Value 0 -Type DWord
        Write-Host "   UAC configured to not prompt administrators for elevation." -ForegroundColor Green
    } else {
        Write-Host "   UAC already configured to not prompt administrators." -ForegroundColor Green
    }
}

# Summary
Write-Host ""
Write-Host "====================================" -ForegroundColor Cyan
Write-Host "Restoration Complete!" -ForegroundColor Green
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""
if ($Selection -band 1) {
    Write-Host "Terminal Settings:" -ForegroundColor Yellow
    Write-Host "  - Close and reopen Windows Terminal" -ForegroundColor White
    Write-Host "  - Your custom theme should now be active!" -ForegroundColor White
    Write-Host ""
}
if ($Selection -band 2) {
    Write-Host "Open Shell:" -ForegroundColor Yellow
    Write-Host "  - Press Win key to see the custom start menu" -ForegroundColor White
    Write-Host ""
}
if ($Selection -band 4) {
    Write-Host "UAC:" -ForegroundColor Yellow
    Write-Host "  - Admin elevations will no longer prompt" -ForegroundColor White
    Write-Host ""
}
Write-Host ""
Read-Host "Press Enter to exit"
