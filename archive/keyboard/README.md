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

## Active Configuration (T14s Backspace Swap)

The following logic is implemented automatically by the restore script:

# How to Swap Backspace and Backslash on Arch/KDE (T14s)
# Method: keyd (system-wide daemon)

1. Identify the keyboard. 'keyd' logs showed it ignoring the T14s keyboard:
   DEVICE: ignoring 0001:0001:09b4e68d (AT Translated Set 2 keyboard)
   We must force 'keyd' to watch this device ID (0001:0001).

2. Create the keyd config file: /etc/keyd/default.conf

   [ids]
   *
   0001:0001

   [main]
   backspace = backslash
   backslash = backspace

3. Enable and start the keyd service:
   sudo systemctl enable keyd
   sudo systemctl start keyd

4. (CRITICAL) Clean up conflicting KDE (xkb) rules:
   - Edit ~/.config/kxkbrc
   - Remove any old keyboard swap options (e.g., "swap_bs_bksl:swap")
     from the "Options=" line.

5. Reboot.
   (A reboot is required to clear Plasma's old xkb settings).
