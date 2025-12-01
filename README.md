# T14s/Arch Sys Restore 

System management and automation tools for ThinkPad T14s AMD Gen 1 running Arch Linux + KDE Plasma.

## Contents

- **[restore/](restore/)** - System restoration script for Borg-based recovery
- **[audio/](audio/)** - Low-latency PipeWire audio configuration (2.67ms latency)
- **[archive/keyboard/](archive/keyboard/)** - USB keyboard management with keyd (Archived)
- **[kde-plasma/](kde-plasma/)** - KDE Plasma configurations and customizations
- **[cron-systemd/](cron-systemd/)** - Automated backup scheduling
- **borg_credentials.example** - Secure credential template
- **crontab.example** - User backup scheduling

## Backup Scripts (~/bin)

Automated Borg backup scripts with credential security:
- **backup_t14s_home** - Home directory backups
- **backup_t14s_sys** - System snapshot backups
- **backup_full_sys** - External drive backups

All scripts require environment variables - no hardcoded credentials. See [cron-systemd/README.md](cron-systemd/README.md) for secure setup.

## Quick Links

- [Restore System Documentation](restore/README.md)
- [Audio Setup Instructions](audio/README.md)
- [Keyboard Scripts Documentation](archive/keyboard/README.md)
- [KDE Plasma Configuration](kde-plasma/README.md)
- [Backup Scheduling](cron-systemd/README.md)
