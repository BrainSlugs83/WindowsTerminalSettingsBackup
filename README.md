# Terminal Settings Backup

This folder contains your custom Windows Terminal configuration, including:

## Contents

1. **settings.json** - Windows Terminal configuration with:
   - Custom background image settings (67% opacity, bottom-right alignment)
   - Hasklug Nerd Font Mono font configuration
   - Acrylic transparency enabled
   - Custom keybindings

2. **Microsoft.PowerShell_profile.ps1** - PowerShell profile that loads oh-my-posh with your custom theme

3. **capr4n.json** - Your custom oh-my-posh theme with:
   - Right-aligned date/time display
   - Execution time indicator
   - Git status with icons
   - Custom path display (max depth 2, agnoster_short style)
   - Custom colors (purple, green, cyan)

4. **wallpaper-60247.jpg** - Your terminal background image

5. **Restore-TerminalSettings.ps1** - Automated restoration script

## How to Restore on Another PC

1. Copy this entire folder to your new PC
2. Download and install **Hasklug Nerd Font Mono** from:
   https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/Hasklig.zip
   - Extract the zip
   - Right-click the font files and select "Install for all users"

3. Right-click on `Restore-TerminalSettings.ps1` and select "Run with PowerShell" (as Administrator)
   - Or open PowerShell as Administrator and run:
     ```powershell
     cd path\to\TerminalSettingsBackup
     .\Restore-TerminalSettings.ps1
     ```

4. Close and reopen Windows Terminal

## What the Script Does

- Installs oh-my-posh if not already present
- Copies background image to `%USERPROFILE%\Pictures\Backgrounds-1080p\`
- Restores Windows Terminal settings (backs up existing ones first)
- Restores PowerShell profile (backs up existing one first)
- Restores oh-my-posh custom theme to `%USERPROFILE%\.config\oh-my-posh\`

## Manual Restoration (if needed)

If you prefer manual setup:

1. Install oh-my-posh: `winget install JanDeDobbeleer.OhMyPosh`
2. Install Hasklug Nerd Font Mono (see link above)
3. Copy `wallpaper-60247.jpg` to `%USERPROFILE%\Pictures\Backgrounds-1080p\`
4. Copy `settings.json` to `%LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\`
5. Copy `Microsoft.PowerShell_profile.ps1` to `%USERPROFILE%\Documents\PowerShell\`
6. Copy `capr4n.json` to `%USERPROFILE%\.config\oh-my-posh\`

## Notes

- The script requires Administrator privileges to install oh-my-posh via winget
- Your existing settings will be backed up with a `.backup` extension
- The Nerd Font is required for icons to display correctly in the prompt
