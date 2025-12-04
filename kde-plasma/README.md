# KDE Plasma Configuration

Scripts and configuration files for KDE Plasma desktop settings management.

## Scripts

### restore-plasma-settings.sh
**Purpose**: Manual, interactive restoration of KDE Plasma settings from repository

**Use case**:
- Applying repo KDE configs to current system
- Interactive with user prompts
- No Borg backup required
- Backs up existing configs before applying

**Usage**:
```bash
./restore-plasma-settings.sh
```

### backup-plasma-settings.sh
**Purpose**: Save current KDE Plasma settings to repository

**Use case**:
- Updating repo with your current KDE configs
- Replaces hardcoded paths with variables
- Creates backup of old repo files

**Usage**:
```bash
./backup-plasma-settings.sh
```

### fix-app-icons.sh
**Purpose**: Fix desktop file issues for various applications in KDE Wayland/X11

**Applications fixed**:
- Signal Desktop
- Bitwig Studio / Bitwig Studio Beta
- Proton Mail Bridge
- Proton VPN
- RCU (reMarkable Connection Utility)

**Usage**:
```bash
./fix-app-icons.sh
```

## Configuration Files

- `plasma-org.kde.plasma.desktop-appletsrc` - Desktop widgets and panels
- `plasmashellrc` - Plasma shell settings
- `kdeglobals` - Global KDE settings
- `kwinrc` - KWin window manager settings
- `kglobalshortcutsrc` - Global keyboard shortcuts
- `dolphinrc` - Dolphin file manager settings
- `konsolerc` - Konsole terminal settings
- `konsole/` - Konsole profiles
- `default.conf` - Keyd keyboard remapping config

## Note

The main system restore script (`../restore/restore-system.sh`) has its own `restore_kde_config()` function which:
- Restores from Borg backup (not from these repo files)
- Runs non-interactively as part of full system restore
- Used by: `./restore-system.sh full-setup` or `./restore-system.sh restore-kde`

Both approaches serve different purposes and coexist intentionally.
