# KDE Plasma Configuration

Custom KDE Plasma and keyd configurations for ThinkPad T14s AMD Gen 1.

## Files

### Keyboard Remapping (keyd)

- **default.conf** - keyd config for swapping backspace ↔ backslash on T14s internal keyboard
  - Install to: `/etc/keyd/default.conf`
  - Requires: `keyd` package
  - Service: `sudo systemctl enable --now keyd`

- **kxkbrc** - KDE keyboard layout settings
  - Install to: `~/.config/kxkbrc`
  - Settings: Caps Lock → Ctrl, Alt ↔ Win swap

- **howto** - Detailed instructions for keyboard remapping setup

### Window Management

- **kwinrc** - KWin window manager configuration
  - Window behavior, focus policy, compositing settings
  - Install to: `~/.config/kwinrc`

### Global Shortcuts

- **kglobalshortcutsrc** - KDE global keyboard shortcuts
  - Custom shortcuts for apps, window management, system actions
  - Install to: `~/.config/kglobalshortcutsrc`

### File Manager

- **dolphinrc** - Dolphin file manager settings
  - View preferences, toolbar customizations
  - Install to: `~/.config/dolphinrc`

### Terminal

- **konsole/default.profile** - Konsole terminal profile
  - Colors, fonts, behavior settings
  - Install to: `~/.local/share/konsole/default.profile`

## Setup

### Keyboard Remapping

1. Install keyd:
   ```bash
   sudo pacman -S keyd
   ```

2. Copy config:
   ```bash
   sudo cp default.conf /etc/keyd/default.conf
   cp kxkbrc ~/.config/
   ```

3. Enable and start service:
   ```bash
   sudo systemctl enable keyd
   sudo systemctl start keyd
   ```

4. Reboot for changes to take full effect

### KDE Settings

Copy config files to their respective locations:

```bash
cp kwinrc ~/.config/
cp kglobalshortcutsrc ~/.config/
cp dolphinrc ~/.config/
mkdir -p ~/.local/share/konsole
cp konsole/default.profile ~/.local/share/konsole/
```

Log out and log back in for changes to apply.

## Notes

- The keyd config specifically targets device ID `0001:0001` (AT Translated Set 2 keyboard) for the T14s internal keyboard
- Clean up any conflicting KDE xkb rules in `~/.config/kxkbrc` if keyboard remapping doesn't work
- Reboot is required to clear Plasma's old xkb settings
- These configs were exported from a working Arch Linux + KDE Plasma setup on ThinkPad T14s
