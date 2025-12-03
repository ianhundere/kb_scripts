# T14s/Arch System Configuration

Complete system management and automation tools for ThinkPad T14s AMD Gen 1 running Arch Linux + KDE Plasma.

## Contents

- [System Restoration](#system-restoration) - Automated Borg-based recovery
- [Audio Configuration](#audio-configuration) - Low-latency PipeWire (2.67ms)
- [Performance Optimizations](#performance-optimizations) - I/O, network, memory tuning
- [KDE Plasma Configuration](#kde-plasma-configuration) - Desktop settings and keyboard remapping
- [Backup Scheduling](#backup-scheduling) - Automated cron-based backups
- [Archive](#archive) - Legacy keyboard scripts

---

# System Restoration

Automated Arch Linux + KDE Plasma system restoration from Borg backups.

## Quick Start

```bash
# Set required environment variables
export BORG_REPO='user@host.repo.borgbase.com:repo'
export BORG_PASSPHRASE='your-passphrase'

# Test run (no changes)
DRY_RUN=true ./restore/restore-system.sh full-setup

# Full restoration
./restore/restore-system.sh full-setup

# Configure backups (optional if not running full-setup)
./restore/restore-system.sh setup-backup

# After reboot, restore music production files (~11GB)
./restore/restore-system.sh restore-music
```

## Features

- Complete data restoration from Borg backup (~33GB)
- 93 packages (67 official repos + 26 AUR)
- Hardware optimization (TLP, Thinkfan, ZRAM, AMD GPU)
- Audio production setup (yabridge, realtime limits, rtirq)
- Security hardening (UFW, SSH keys-only)
- Dry run mode for safe testing

## Usage

```bash
./restore/restore-system.sh COMMAND [OPTIONS]

Commands:
  full-setup          Complete system restoration (everything except music)
  restore-shell       Restore zsh/p10k shell config
  restore-kde         Restore KDE Plasma settings
  restore-data        Restore user data directories
  restore-app-configs Restore app configs (Calibre, VS Code, etc.)
  restore-music       Restore music production (Bitwig, VSTs, Wine)
  install-apps        Install desktop applications only
  install-flatpaks    Install flatpak applications (Thunderbird, ProtonVPN, etc.)
  install-music       Install music production stack only
  setup-backup        Configure backup tools (Timeshift + cron)
  setup-audio         Configure low-latency PipeWire audio
  setup-power         Configure T14s power management only
  setup-security      Configure firewall + SSH hardening only
  setup-performance   Apply system performance optimizations
  fix-icons           Fix desktop icons for KDE Wayland/X11

Options:
  --dry-run          Simulate without making changes
```

## Prerequisites

1. Arch Linux installation with base system
2. Borg backup accessible (mounted or remote)
3. Internet connection
4. Sudo privileges

## Post-Restore Tasks

1. Reboot for kernel modules (ZRAM, fan control)
2. Log out/in for group membership (audio, docker)
3. Reload shell: `source ~/.zshrc`
4. Browser sync (Firefox Sync, VS Code Settings Sync)
5. Fingerprint enrollment: `fprintd-enroll`

## Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `BORG_PASSPHRASE_HOME` | Yes | - | Encryption passphrase for home backup repository |
| `BORG_PASSPHRASE_SYS` | Yes | - | Encryption passphrase for system backup repository |
| `BORG_REPO_HOME` | Yes | - | Repository path for home backups |
| `BORG_REPO_SYS` | Yes | - | Repository path for system snapshots |
| `BORG_REPO_FULL` | Yes | - | Repository for full drive backups |
| `BACKUP_DRIVE` | No | - | Path to external backup drive (for full drive backups) |
| `RESTORE_USER` | No | `$USER` | Username to restore for |
| `DRY_RUN` | No | `false` | Set to `true` for test run |

## Packages

- Base tools: git, vim, curl, wget, htop, btop, ripgrep, jq, etc.
- KDE: plasma-meta, dolphin, konsole, kate, etc.
- Desktop apps: Firefox, VS Code, Obsidian, Signal, Discord, Calibre, fastfetch, etc.
- Audio: Pipewire stack, VLC, Kdenlive, etc.
- Music production: wine-staging, winetricks, picard, pipewire-jack, rtirq, etc.
- Hardware: TLP, thinkfan, AMD drivers, fingerprint, etc.
- Languages: Python, Go, Rust, Docker, kubectl, etc.
- AUR: bitwig-studio, yabridge-bin, ocenaudio-bin, sononym, mission-center, piper-tts-bin, etc.
- Backup: borg, timeshift, cronie

## Troubleshooting

**Check logs:**
```bash
tail -f ~/restore-system.log
```

**Dry run:**
```bash
DRY_RUN=true ./restore/restore-system.sh full-setup
```

**Individual components:**
```bash
./restore/restore-system.sh restore-shell      # Just shell config
./restore/restore-system.sh restore-kde        # Just KDE settings
./restore/restore-system.sh restore-data       # Just user data
```

---

# Audio Configuration

Low-latency PipeWire and WirePlumber configuration optimized for real-time audio work.

## Specs

- **Latency**: ~2.67ms (quantum=128 @ 48kHz)
- **Sample Rate**: 48kHz
- **Period Size**: 128 frames
- **Audio Card**: Family 17h/19h/1ah HD Audio Controller (Realtek ALC257)

## Configuration

### 1. PipeWire Settings

**File**: `audio/pipewire/99-lowlatency.conf`
- **Quantum**: 128 frames
- **Latency**: ~2.67ms @ 48kHz
- **RT priority**: 88

### 2. WirePlumber ALSA Settings

**File**: `audio/wireplumber/90-alsa-lowlatency.lua`
- **Period size**: 128 frames
- **Batch mode**: disabled
- **Sample rate**: locked to 48kHz

## Installation

Automated install via restore script:
```bash
./restore/restore-system.sh setup-audio
```

Manual installation:
```bash
mkdir -p ~/.config/pipewire/pipewire.conf.d
cp audio/pipewire/99-lowlatency.conf ~/.config/pipewire/pipewire.conf.d/

mkdir -p ~/.config/wireplumber/main.lua.d
cp audio/wireplumber/90-alsa-lowlatency.lua ~/.config/wireplumber/main.lua.d/

# Restart PipeWire services
systemctl --user restart pipewire pipewire-pulse wireplumber
```

## Verify Settings

```bash
# Check current quantum and rate
pw-metadata -n settings

# Test audio
speaker-test -t wav -c 2 -l 1 -D pipewire

# Monitor real-time performance
pw-top
```

## Realtime Privileges

System configured with:
- **realtime-privileges** package (via PAM)
- **rtirq** for IRQ threading (Audio prio 90)
- **threadirqs** kernel parameter

Verify:
```bash
ulimit -r   # Should be 95
ulimit -l   # Should be unlimited
```

## Troubleshooting

If you experience audio dropouts or glitches:
1. Increase quantum to 256 in `99-lowlatency.conf`
2. Increase period-size to 256 in `90-alsa-lowlatency.lua`
3. Check for CPU throttling or high system load

---

# Performance Optimizations

System-wide performance tuning based on [Arch Wiki: Improving Performance](https://wiki.archlinux.org/title/Improving_performance).

## Overview

- **Storage Performance** - I/O schedulers, TRIM, mount options
- **System Responsiveness** - Sysctl tuning, OOM management, process priorities
- **Compilation Speed** - CPU-specific optimizations for package building
- **Network Performance** - TCP/IP stack tuning

## Configuration Files

### Automatic (Applied by restore script)

| File | Destination | Purpose |
|------|-------------|---------|
| `performance/60-ioschedulers.rules` | `/etc/udev/rules.d/` | Optimizes I/O schedulers per device type |
| `performance/99-sysctl-performance.conf` | `/etc/sysctl.d/` | System-wide kernel tuning |

### Manual Review Required

| File | Usage | Why Manual? |
|------|-------|-------------|
| `performance/makepkg.conf.patch` | Merge into `/etc/makepkg.conf` | Needs review of existing CFLAGS |
| `performance/fstab.optimized` | Apply to `/etc/fstab` | Filesystem-specific, requires review |

## Applied Optimizations

### 1. I/O Schedulers

Automatically selects optimal I/O scheduler based on storage type:

- **NVMe**: `none` (hardware queue management is superior)
- **SSD**: `mq-deadline` (low latency, good for most workloads)
- **HDD**: `bfq` (better responsiveness on rotational media)

Read-ahead values:
- SSD/NVMe: 128KB (favors random access)
- HDD: 1024KB (favors sequential reads)

**Verify:**
```bash
cat /sys/block/nvme0n1/queue/scheduler  # Should show: [none]
cat /sys/block/sda/queue/scheduler       # Should show: [mq-deadline] or [bfq]
```

### 2. System Tuning (Sysctl)

#### Memory Management

- `vm.vfs_cache_pressure=50` - Balance cache retention
- `vm.dirty_ratio=10` - Start forcing writes at 10% RAM
- `vm.dirty_background_ratio=5` - Background writeback at 5% RAM

#### Network Performance

- **BBR Congestion Control** - Modern TCP algorithm
- **TCP Fast Open** - Reduces connection latency
- **Increased buffer sizes** - Better for high-bandwidth connections

Benefits:
- Large file transfers (Syncthing, borg backups)
- Remote development (SSH, code-server)
- Video conferencing

#### File System

- `fs.inotify.max_user_watches=524288` - Essential for IDEs, file sync, build systems
- `fs.file-max=2097152` - Increased file handle limit

#### Kernel

- `kernel.sysrq=1` - Magic SysRq key for emergency recovery
  - `Alt+SysRq+r` - Switch keyboard mode
  - `Alt+SysRq+e` - SIGTERM all processes
  - `Alt+SysRq+i` - SIGKILL all processes
  - `Alt+SysRq+s` - Sync filesystems
  - `Alt+SysRq+u` - Remount read-only
  - `Alt+SysRq+b` - Reboot immediately
  - **Mnemonic**: **R**aising **E**lephants **I**s **S**o **U**tterly **B**oring

**Verify:**
```bash
sysctl vm.vfs_cache_pressure vm.dirty_ratio net.ipv4.tcp_congestion_control
sysctl fs.inotify.max_user_watches
```

### 3. OOM Management (systemd-oomd)

Enables systemd's Out-Of-Memory daemon:
- Monitors memory pressure
- Kills processes before system becomes unresponsive
- Better than kernel OOM killer (acts earlier)

**Verify:**
```bash
systemctl status systemd-oomd
```

### 4. SSD TRIM (fstrim.timer)

Enables weekly TRIM operations:
- Maintains SSD performance over time
- Reduces write amplification
- Extends SSD lifespan

**Verify:**
```bash
systemctl status fstrim.timer
sudo fstrim -v /  # Manual test
```

### 5. Process Priority (ananicy-cpp)

Automatically adjusts process nice levels:
- Prioritizes interactive applications
- De-prioritizes background tasks
- Improves system responsiveness under load

**Verify:**
```bash
systemctl status ananicy-cpp
```

## Manual Optimizations

### makepkg.conf (Compilation Speed)

**File:** `performance/makepkg.conf.patch`

Optimizes package compilation for Ryzen 7 PRO 4750U:

```bash
CFLAGS="-march=native -mtune=native -O2 -pipe ..."
MAKEFLAGS="-j$(nproc)"  # Use all 16 threads
```

**Benefits:**
- ~10-30% faster compilation
- CPU-specific optimizations (AVX2, FMA3, etc.)
- Reduced build times for AUR packages

**Apply:**
```bash
sudo cp /etc/makepkg.conf /etc/makepkg.conf.backup
# Review performance/makepkg.conf.patch
# Manually merge CFLAGS, MAKEFLAGS into /etc/makepkg.conf
```

**Note:** `-march=native` makes packages non-portable. Only use for personal system.

### fstab Mount Options

**File:** `performance/fstab.optimized`

Recommended optimizations for SSD/NVMe with LUKS:

```bash
# Before (typical defaults):
UUID=xxx / ext4 rw,relatime 0 1

# After (performance optimized):
UUID=xxx / ext4 rw,noatime,commit=60 0 1
```

**Key changes:**
- `noatime` → Eliminates access time writes (10-15% fewer writes)
- `commit=60` → Reduce commit frequency (less SSD wear)

**Note:** This system uses LUKS encryption. The optimized fstab does NOT include `discard=async` for safety. Instead, `fstrim.timer` provides weekly TRIM.

**Apply:**
```bash
sudo cp /etc/fstab /etc/fstab.backup
sudo cp performance/fstab.optimized /etc/fstab
sudo systemctl daemon-reload
# Reboot to apply
```

## Performance Impact

### Expected Improvements

| Optimization | Impact | Workload |
|--------------|--------|----------|
| I/O Schedulers | 5-20% faster | Random I/O, app launches |
| Sysctl (network) | 10-50% faster | Large file transfers, SSH |
| Sysctl (memory) | Smoother | Heavy RAM usage scenarios |
| systemd-oomd | Prevents freezes | Memory pressure situations |
| fstrim | Maintains speed | Long-term SSD performance |
| ananicy-cpp | More responsive | Multitasking, heavy loads |
| makepkg -march=native | 10-30% faster | AUR package compilation |
| fstab noatime | 10-15% fewer writes | General usage |

### Benchmarking

Test storage performance:
```bash
# Sequential read speed
hdparm -t /dev/nvme0n1

# I/O performance
fio --name=random-write --ioengine=libaio --rw=randwrite --bs=4k --size=1g --numjobs=4 --runtime=60 --time_based --end_fsync=1

# Filesystem operations
bonnie++ -u $USER
```

Test network throughput:
```bash
# Local network
iperf3 -c <server-ip>

# Internet (single connection)
curl -o /dev/null https://speed.hetzner.de/100MB.bin
```

## Usage

### Apply via restore script

```bash
./restore/restore-system.sh setup-performance
```

### Apply manually

```bash
# I/O schedulers
sudo cp performance/60-ioschedulers.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules && sudo udevadm trigger

# Sysctl tuning
sudo cp performance/99-sysctl-performance.conf /etc/sysctl.d/
sudo sysctl --system

# OOM daemon
sudo systemctl enable --now systemd-oomd

# TRIM timer
sudo systemctl enable --now fstrim.timer

# Process priority (requires yay)
yay -S ananicy-cpp
sudo systemctl enable --now ananicy-cpp
```

## Compatibility

**Tested on:**
- ThinkPad T14s AMD Gen 1 (Ryzen 7 PRO 4750U)
- Arch Linux (kernel 6.x+)
- ext4 root filesystem with LUKS encryption
- NVMe SSD

**Should work on:**
- Any modern AMD Ryzen system
- Kernel 5.6+ (for async discard)
- Any Linux distribution using systemd
- ext4, Btrfs, XFS, F2FS filesystems

## Troubleshooting

### I/O Scheduler not applied

```bash
# Check current scheduler
cat /sys/block/nvme0n1/queue/scheduler

# Manually set (temporary)
echo none | sudo tee /sys/block/nvme0n1/queue/scheduler

# Check udev rules
sudo udevadm test /sys/block/nvme0n1
```

### Sysctl parameters not applied

```bash
# Check if loaded
sysctl net.ipv4.tcp_congestion_control

# Reload all sysctl configs
sudo sysctl --system

# Check for errors
sudo journalctl -u systemd-sysctl
```

### systemd-oomd triggering too aggressively

```bash
# Check memory pressure
systemd-analyze cat-config systemd/oomd.conf

# View OOM events
journalctl -u systemd-oomd
```

### LUKS Encryption & TRIM

**System uses LUKS encryption** - `fstab.optimized` uses `noatime` and `commit=60` but NOT `discard=async` for safety. Instead, `fstrim.timer` provides weekly TRIM.

**If TRIM fails** (`fstrim: the discard operation is not supported`):

```bash
# Enable LUKS discard support
./performance/enable-luks-trim.sh
sudo reboot
```

This adds `:allow-discards` to boot parameters and enables LVM discard. Minor security trade-off (used blocks visible) for SSD longevity.

## References

- [Arch Wiki: Improving Performance](https://wiki.archlinux.org/title/Improving_performance)
- [Arch Wiki: Solid State Drive](https://wiki.archlinux.org/title/Solid_state_drive)
- [Arch Wiki: Sysctl](https://wiki.archlinux.org/title/Sysctl)
- [Arch Wiki: systemd-oomd](https://wiki.archlinux.org/title/Systemd/oomd)
- [ThinkPad T14s AMD Gen 1](https://wiki.archlinux.org/title/Lenovo_ThinkPad_T14s_(AMD)_Gen_1)

---

# KDE Plasma Configuration

Custom KDE Plasma and keyd configurations for ThinkPad T14s AMD Gen 1.

## Files

### Keyboard Remapping (keyd)

- **kde-plasma/default.conf** - keyd config for swapping backspace ↔ backslash on T14s internal keyboard
  - Install to: `/etc/keyd/default.conf`
  - Requires: `keyd` package
  - Service: `sudo systemctl enable --now keyd`

- **kde-plasma/kxkbrc** - KDE keyboard layout settings
  - Install to: `~/.config/kxkbrc`
  - Settings: Caps Lock → Ctrl, Alt ↔ Win swap

### Window Management

- **kde-plasma/kwinrc** - KWin window manager configuration
  - Window behavior, focus policy, compositing settings
  - Install to: `~/.config/kwinrc`

### Global Shortcuts

- **kde-plasma/kglobalshortcutsrc** - KDE global keyboard shortcuts
  - Custom shortcuts for apps, window management, system actions
  - Install to: `~/.config/kglobalshortcutsrc`

### File Manager

- **kde-plasma/dolphinrc** - Dolphin file manager settings
  - View preferences, toolbar customizations
  - Install to: `~/.config/dolphinrc`

### Terminal

- **kde-plasma/konsole/default.profile** - Konsole terminal profile
  - Colors, fonts, behavior settings
  - Install to: `~/.local/share/konsole/default.profile`

### Plasma Desktop

- **kde-plasma/plasmarc** - Plasma desktop configuration
  - Desktop behavior and settings
  - Install to: `~/.config/plasmarc`

- **kde-plasma/plasmashellrc** - Plasma shell configuration
  - Panel layout, widgets, shell behavior
  - Install to: `~/.config/plasmashellrc`

- **kde-plasma/plasma-org.kde.plasma.desktop-appletsrc** - Desktop widgets/applets
  - Taskbar, system tray, desktop widgets configuration
  - Install to: `~/.config/plasma-org.kde.plasma.desktop-appletsrc`

### Display Configuration

- **kde-plasma/kwinoutputconfig.json** - Display/monitor configuration
  - Screen arrangement, resolution, scaling settings
  - Install to: `~/.config/kwinoutputconfig.json`

## Setup

### Keyboard Remapping

1. Install keyd:
   ```bash
   sudo pacman -S keyd
   ```

2. Copy config:
   ```bash
   sudo cp kde-plasma/default.conf /etc/keyd/default.conf
   cp kde-plasma/kxkbrc ~/.config/
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
cp kde-plasma/kwinrc ~/.config/
cp kde-plasma/kglobalshortcutsrc ~/.config/
cp kde-plasma/dolphinrc ~/.config/
cp kde-plasma/plasmarc ~/.config/
cp kde-plasma/plasmashellrc ~/.config/
cp kde-plasma/plasma-org.kde.plasma.desktop-appletsrc ~/.config/
cp kde-plasma/kwinoutputconfig.json ~/.config/
mkdir -p ~/.local/share/konsole
cp kde-plasma/konsole/default.profile ~/.local/share/konsole/
```

Log out and log back in for changes to apply (or restart Plasma shell with `kquitapp5 plasmashell && kstart5 plasmashell`).

## Notes

- The keyd config specifically targets device ID `0001:0001` (AT Translated Set 2 keyboard) for the T14s internal keyboard
- Clean up any conflicting KDE xkb rules in `~/.config/kxkbrc` if keyboard remapping doesn't work
- Reboot is required to clear Plasma's old xkb settings
- These configs were exported from a working Arch Linux + KDE Plasma setup on ThinkPad T14s

---

# Backup Scheduling

Automated backup scheduling for Borg and Timeshift, including mutual exclusion.

## Backup Scripts (~/bin)

Automated Borg backup scripts:
- **backup_t14s_home** - Home directory backups
- **backup_t14s_sys** - System snapshot backups
- **backup_full_sys** - External drive backups (requires `BACKUP_DRIVE` env var)

All scripts use environment variables for credentials and will exit if required variables are not set.

## Cron Automation

### User Crontab (Hourly Home Backup)

Your user's crontab now includes:
- **Home backup**: Hourly (at :00) for `backup_t14s_home`, logs to `~/.cache/borg_home.log`.
  ```bash
  0 * * * * . ~/.config/borg/env && ~/bin/backup_t14s_home >> ~/.cache/borg_home.log 2>&1
  ```

### System Crontab (Timeshift & Daily System Backup)

The system's root crontab and `/etc/cron.d/` files are configured:

1.  **Timeshift (Hourly & On-boot)**:
    *   `/etc/cron.d/timeshift-boot`: Creates a snapshot 10m after boot.
    *   `/etc/cron.d/timeshift-hourly`: Creates/checks snapshots hourly (at :30).
    *   **Mutual Exclusion:** Both Timeshift jobs now include a check to skip if any Borg backup is detected as running.

2.  **System Backup (Daily)**:
    *   `0 3 * * * . /home/ianfundere/.config/borg/env && /home/ianfundere/bin/backup_t14s_sys >> /var/log/borg_sys.log 2>&1`
    *   Runs daily at 03:00 AM for `backup_t14s_sys`, logs to `/var/log/borg_sys.log`.
    *   **Mutual Exclusion:** This job skips if Timeshift is detected as running.

## Secure Credentials Setup

Credentials for Borg backups are stored securely in an environment file.

**Setup:**

1.  **Edit `~/.config/borg/env`**: This file was created with restricted permissions (`chmod 600`).
    ```bash
    nano ~/.config/borg/env
    ```
    Fill in the placeholders for:
    *   `BORG_PASSPHRASE_HOME`
    *   `BORG_PASSPHRASE_SYS`
    *   `BORG_REPO_HOME`
    *   `BORG_REPO_SYS`
    *   (Optionally) `BORG_REPO_FULL` if using `backup_full_sys`.

    The cron jobs are configured to source this file, providing the necessary environment variables to your backup scripts. This keeps credentials out of crontab entries and the scripts themselves.

---

# Archive

## Keyboard Management Scripts (ARCHIVED)

**Note:** These scripts were used with Pop!_OS and other distros, not KDE Plasma. Now archived - active keyboard configs are in `kde-plasma/`.

Scripts for managing multiple USB keyboards with keyd.

### Scripts

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

### Setup

1. Copy udev rules: `sudo cp archive/keyboard/kb.rules /etc/udev/rules.d/`
2. Reload udev: `sudo udevadm control --reload-rules`
3. Make scripts executable: `chmod +x archive/keyboard/*`
4. Configure keyd for your keyboard layouts

### Usage

Scripts are typically triggered automatically via udev when keyboards are connected/disconnected.

### Active Configuration (T14s Backspace Swap)

The following logic is implemented automatically by the restore script:

**How to Swap Backspace and Backslash on Arch/KDE (T14s)**
**Method:** keyd (system-wide daemon)

1. Identify the keyboard. 'keyd' logs showed it ignoring the T14s keyboard:
   ```
   DEVICE: ignoring 0001:0001:09b4e68d (AT Translated Set 2 keyboard)
   ```
   We must force 'keyd' to watch this device ID (0001:0001).

2. Create the keyd config file: `/etc/keyd/default.conf`
   ```
   [ids]
   *
   0001:0001

   [main]
   backspace = backslash
   backslash = backspace
   ```

3. Enable and start the keyd service:
   ```bash
   sudo systemctl enable keyd
   sudo systemctl start keyd
   ```

4. **(CRITICAL)** Clean up conflicting KDE (xkb) rules:
   - Edit `~/.config/kxkbrc`
   - Remove any old keyboard swap options (e.g., "swap_bs_bksl:swap") from the "Options=" line

5. Reboot (required to clear Plasma's old xkb settings)
