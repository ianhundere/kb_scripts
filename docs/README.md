# Documentation - sys-restore-t14s-arch

Documentation for ThinkPad T14s AMD Gen 1 system restoration and configuration.

---

## Audio Configuration

### [audio-configuration-summary.md](./audio-configuration-summary.md)
**Main reference document for audio setup** (10KB)

Complete guide covering:
- Low-latency PipeWire configuration (128 frames @ 48kHz = 2.67ms)
- Realtime privileges setup (realtime-privileges package)
- IRQ priority configuration (rtirq)
- PipeWire realtime scheduling verification
- System restore integration
- Troubleshooting guide
- Future: Allen & Heath Qu-Pac integration notes

**Start here** for audio configuration reference.

### [AUDIO_STATUS.md](./AUDIO_STATUS.md)
**Quick status check** (2.5KB)

Quick reference showing:
- Current system status (all optimal ✓)
- Installed packages
- Active services
- RT limits verification
- Key metrics

Use for quick verification that audio is configured correctly.

### [FINAL-CHANGES-SUMMARY.md](./FINAL-CHANGES-SUMMARY.md)
**Summary of changes made 2025-11-27** (6.1KB)

Historical record of audio configuration session:
- All changes made
- Before/after comparison
- Files created/modified
- Testing completed

Point-in-time snapshot of the audio setup work.

### [restore-script-changes.md](./restore-script-changes.md)
**Restore script modifications** (5KB)

Details on restore script updates:
- New `setup_audio_lowlatency()` function
- Updated `install_music_production()` function
- Usage examples
- Dry-run testing
- Integration points

Reference for understanding restore script audio integration.

---

## Configuration Files

Audio configuration files are stored in `../audio/`:
- `audio/pipewire/99-lowlatency.conf`
- `audio/wireplumber/90-alsa-lowlatency.lua`
- `audio/README.md`

---

## Quick Links

**Audio setup**:
```bash
cd ../restore
./restore-system.sh setup-audio
```

**Full system restore**:
```bash
cd ../restore
./restore-system.sh full-setup
```

**Verify audio**:
```bash
pw-metadata -n settings | grep quantum
ps -eLo pid,tid,class,rtprio,comm | grep pipewire
```

---

**Last updated**: 2025-11-27
