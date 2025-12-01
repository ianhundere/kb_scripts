# System Restoration Script

Automated Arch Linux + KDE Plasma system restoration from Borg backups for ThinkPad T14s AMD Gen 1.

## Quick Start

```bash
# Set required environment variables
export BORG_REPO='user@host.repo.borgbase.com:repo'
export BORG_PASSPHRASE='your-passphrase'

# Test run (no changes)
DRY_RUN=true ./restore-system.sh full-setup

# Full restoration
./restore-system.sh full-setup

# Configure backups (optional if not running full-setup)
./restore-system.sh setup-backup

# After reboot, restore music production files (~11GB)
./restore-system.sh restore-music
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
./restore-system.sh COMMAND [OPTIONS]

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
  setup-audio         Configure low-latency PipeWire audio (quantum=128, ~2.67ms latency)
  setup-power         Configure T14s power management only
  setup-security      Configure firewall + SSH hardening only
  fix-icons           Fix desktop icons for KDE Wayland/X11 (Signal, Bitwig, Proton apps)

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
| `BORG_REPO` | Yes | - | Borg repository path (user@host:repo) |
| `BORG_PASSPHRASE` | Yes | - | Repository encryption passphrase |
| `RESTORE_USER` | No | `$USER` | Username to restore for |
| `DRY_RUN` | No | `false` | Set to `true` for test run |

## Packages

- Base tools: git, vim, curl, wget, htop, btop, ripgrep, jq, etc.
- KDE: plasma-meta, dolphin, konsole, kate, etc.
- Desktop apps: Firefox, VS Code, Obsidian, Signal, Discord, Calibre, fastfetch, etc.
- Audio: Pipewire stack, VLC, Kdenlive, etc.
- Music production: wine-staging, winetricks, picard, jack2, rtirq, etc.
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
DRY_RUN=true ./restore-system.sh full-setup
```

**Individual components:**
```bash
./restore-system.sh restore-shell      # Just shell config
./restore-system.sh restore-kde        # Just KDE settings
./restore-system.sh restore-data       # Just user data
```
