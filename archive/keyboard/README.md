# Keyboard Management Scripts (ARCHIVED)

**Note:** These scripts were used with Pop!_OS and other distros, not KDE Plasma. Now archived - active keyboard configs are in `../kde-plasma/`.

Scripts for managing multiple USB keyboards with keyd.

## Scripts

- `apple_kb` - Keyd config for Apple keyboard layout
- `doro_kb` - Keyd config for Doro keyboard layout
- `lenovo_kb` - Keyd config for Lenovo keyboard layout
- `lenovo_kb_on_wake` - Auto-apply Lenovo config on system wake
- `kb.rules` - udev rules for automatic keyboard detection
- `connect` - Script to connect USB keyboard
- `disconnect` - Script to disconnect USB keyboard
- `keyboard-add` - Add new keyboard configuration
- `keyboard-add-start` - Auto-start keyboard-add
- `keyboard-remove` - Remove keyboard configuration
- `keyboard-remove-start` - Auto-start keyboard-remove

## Setup

1. Copy udev rules: `sudo cp kb.rules /etc/udev/rules.d/`
2. Reload udev: `sudo udevadm control --reload-rules`
3. Make scripts executable: `chmod +x *`
4. Configure keyd for your keyboard layouts

## Usage

Scripts are typically triggered automatically via udev when keyboards are connected/disconnected.
