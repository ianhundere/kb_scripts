# PipeWire Audio Configuration Summary - T14s

**Date**: 2025-11-27
**System**: Arch Linux, ThinkPad T14s (AMD)
**Audio Controller**: Family 17h/19h/1ah HD Audio Controller (Realtek ALC257)

---

## Changes Made

### 1. Audio Profile Switch
**Changed from**: `pro-audio` mode (manual JACK-style routing)
**Changed to**: `HiFi (Mic1, Mic2, Speaker)` mode (automatic routing)

```bash
pactl set-card-profile alsa_card.pci-0000_07_00.6 "HiFi (Mic1, Mic2, Speaker)"
```

**Why**: Pro-audio mode requires manual connection of audio streams to outputs. HiFi mode provides automatic routing suitable for desktop applications like Sononym.

---

### 2. Low-Latency Configuration

#### PipeWire Settings
**File**: `~/.config/pipewire/pipewire.conf.d/99-lowlatency.conf`

**Key changes**:
- **Quantum**: 512 → 128 frames
- **Latency**: ~10.67ms → ~2.67ms @ 48kHz (4x improvement)
- **Min quantum**: 64 frames (allows apps to request even lower)
- **RT priority**: 88 with nice level -11

#### WirePlumber ALSA Settings
**File**: `~/.config/wireplumber/main.lua.d/90-alsa-lowlatency.lua`

**Key changes**:
- **Period size**: 1024 → 128 frames
- **Period count**: 2 periods
- **Batch mode**: disabled (lower latency)
- **Suspend timeout**: 0 (never suspend, prevents dropouts)
- **Sample rate**: locked to 48kHz

---

### 3. ALSA Default Device Configuration

**File**: `~/.asoundrc`

```
pcm.!default {
    type pipewire
}

ctl.!default {
    type pipewire
}
```

**Why**: Routes all ALSA applications through PipeWire by default.

---

## Current Audio Stack

```
Applications (Sononym, etc)
       ↓
   ALSA / PulseAudio API
       ↓
    PipeWire
       ↓
  ALSA Kernel Driver
       ↓
   Hardware (ALC257)
```

**Compatibility**:
- ✅ ALSA applications → via PipeWire ALSA plugin
- ✅ PulseAudio applications → via `pipewire-pulse`
- ✅ JACK applications → via PipeWire JACK compatibility

---

## Services Status

All running as **user services** (not system services):

```bash
systemctl --user status pipewire pipewire-pulse wireplumber
```

- **pipewire.service**: Main audio server
- **pipewire-pulse.service**: PulseAudio compatibility layer
- **wireplumber.service**: Session/policy manager

---

## Verification Commands

```bash
# Check current settings
pw-metadata -n settings

# Expected output:
# clock.quantum: 128
# clock.rate: 48000
# clock.min-quantum: 64
# clock.max-quantum: 2048

# List audio devices
wpctl status

# Test audio playback
speaker-test -t wav -c 2 -l 1 -D pipewire

# Monitor real-time performance
pw-top

# Check for xruns/dropouts
journalctl --user -u pipewire -f
```

---

## Backup Location

All configuration files backed up to:
`~/projects/sys-restore-t14s-arch/audio/`

```
audio/
├── pipewire/
│   └── 99-lowlatency.conf
├── wireplumber/
│   └── 90-alsa-lowlatency.lua
└── README.md
```

## System Restore Integration

Audio configuration has been integrated into the system restore script.

**Automated restore (includes in full-setup)**:
```bash
cd ~/projects/sys-restore-t14s-arch/restore
./restore-system.sh setup-audio
```

This will:
- Copy PipeWire low-latency config from `audio/` directory
- Copy WirePlumber ALSA config
- Create `~/.asoundrc` for ALSA default device
- Set audio card to HiFi profile
- Restart PipeWire services
- Verify quantum settings

**Manual restore command**:
```bash
cd ~/projects/sys-restore-t14s-arch/audio/
mkdir -p ~/.config/pipewire/pipewire.conf.d
mkdir -p ~/.config/wireplumber/main.lua.d
cp pipewire/99-lowlatency.conf ~/.config/pipewire/pipewire.conf.d/
cp wireplumber/90-alsa-lowlatency.lua ~/.config/wireplumber/main.lua.d/
systemctl --user restart pipewire pipewire-pulse wireplumber
```

**Test with dry-run**:
```bash
cd ~/projects/sys-restore-t14s-arch/restore
DRY_RUN=true ./restore-system.sh setup-audio
```

---

## Troubleshooting

### Audio Glitches/Dropouts
If experiencing xruns or audio glitches:

1. **Increase buffer size**:
   - Edit `~/.config/pipewire/pipewire.conf.d/99-lowlatency.conf`
   - Change `default.clock.quantum = 128` to `256`
   - Restart: `systemctl --user restart pipewire`

2. **Increase ALSA period size**:
   - Edit `~/.config/wireplumber/main.lua.d/90-alsa-lowlatency.lua`
   - Change `["api.alsa.period-size"] = 128` to `256`
   - Restart: `systemctl --user restart wireplumber`

3. **Check CPU governor**:
   ```bash
   cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
   # Should be "performance" for audio work
   ```

### Sononym Not Playing Audio
1. Restart Sononym to pick up new audio configuration
2. Check Sononym's audio settings (Preferences → Audio)
3. Ensure it's using PipeWire/PulseAudio backend
4. Verify audio is working: `speaker-test -t wav -c 2 -l 1 -D pipewire`

### Revert to Pro-Audio Mode
```bash
pactl set-card-profile alsa_card.pci-0000_07_00.6 pro-audio
```

---

## Realtime Audio Configuration ✅

### Packages Installed

**1. realtime-privileges (5-1)**
- **Status**: ✅ Installed from `pro-audio` package group
- **Purpose**: Provides PAM configuration for realtime privileges
- **Group**: Creates `realtime` group with RT scheduling access
- **Configuration**: Automatic via PAM (no manual `/etc/security/limits.d/` needed)

**2. rtirq (20240905-1)**
- **Status**: ✅ Installed and enabled
- **Purpose**: IRQ threading priority for audio hardware
- **Service**: `rtirq.service` - active since boot
- **Config**: `/etc/rtirq.conf`

### User Group Membership ✅

```bash
$ groups
ianfundere realtime audio wheel
```

**Required groups**:
- ✅ `realtime` - RT scheduling privileges (from realtime-privileges)
- ✅ `audio` - Audio device access and RT limits

### Realtime Limits Active ✅

```bash
$ ulimit -r   # Realtime priority
95

$ ulimit -l   # Locked memory
unlimited
```

**Configuration source**: Automatic via `realtime-privileges` package through PAM

### RTKit Daemon ✅

```bash
$ systemctl status rtkit-daemon.service
● rtkit-daemon.service - RealtimeKit Scheduling Policy Service
     Active: active (running)
```

**Purpose**: D-Bus service that grants RT scheduling to user processes
**Used by**: PipeWire, audio applications

### IRQ Priority Configuration ✅

**Service**: `rtirq.service` - enabled and running
**Config**: `/etc/rtirq.conf`

```bash
RTIRQ_NAME_LIST="snd_hda_intel usb i8042"
RTIRQ_PRIO_HIGH=90
RTIRQ_PRIO_DECR=5
RTIRQ_RESET_ALL=0
```

**Current IRQ priorities**:
```
Audio (snd_hda_intel):   IRQ 138,139 → Priority 90,89 (highest)
USB controllers:         IRQ 50,59,107 → Priority 85-83
Keyboard/mouse (i8042):  IRQ 1,12 → Priority 80,79
```

**Kernel parameter**: `threadirqs` ✅ Enabled (required for rtirq)

### PipeWire Realtime Scheduling ✅

**Module**: `libpipewire-module-rt` - loaded with custom config

**Thread scheduling** (verified with `ps -eLo`):
```
  PID     TID CLASS RTPRIO  NI COMMAND
67615   67615 TS       -   -11 pipewire         # Main thread: nice=-11
67615   67619 FF      88     - data-loop.0     # Audio thread: FIFO RT priority 88 ✓
```

**Status**: ✅ **OPTIMAL**
- Main thread: elevated nice priority (-11) for responsiveness
- Audio processing thread: **FIFO realtime priority 88**
- This is the correct configuration for low-latency professional audio

### Performance Metrics

**Current configuration**:
- **Latency**: ~2.67ms (128 frames @ 48kHz)
- **Audio RT Priority**: FIFO 88
- **IRQ Priority**: 90 (audio hardware)
- **Improvement**: 4x better than default (10.67ms → 2.67ms)

**Comparison to Pro Audio Standards**:

| System | Quantum | Latency | RT Priority |
|--------|---------|---------|-------------|
| **T14s (current)** | 128 | 2.67ms | 88 |
| Pro DAW default | 256 | 5.33ms | 83 |
| Pro DAW low-latency | 64 | 1.33ms | 90 |
| Live performance | 32-64 | 0.67-1.33ms | 95 |

**Assessment**: Optimal for music production, sample browsing, plugin processing, and recording with monitoring.

---

## Future Configuration

### Allen & Heath Qu-Pac Digital Mixer

**Status**: Pending configuration

**Requirements**:
- USB audio interface support
- Class-compliant USB audio (likely supported)
- May need pro-audio mode for multi-channel routing
- May need separate WirePlumber rules for USB suspend prevention

**Configuration location**: TBD
- Will add to `~/projects/sys-restore-t14s-arch/audio/`
- May need separate profile for USB vs built-in audio

**Notes**:
- Qu-Pac provides multi-channel I/O (likely 32×32 @ 48kHz)
- Will require manual routing in pro-audio mode or JACK
- Consider separate quantum settings for USB interface
- USB audio typically benefits from suspend timeout = 0

---

## References

- PipeWire docs: https://docs.pipewire.org/
- WirePlumber docs: https://pipewire.pages.freedesktop.org/wireplumber/
- Arch Wiki PipeWire: https://wiki.archlinux.org/title/PipeWire
- Low-latency config reference: https://github.com/robbert-vdh/dotfiles/blob/master/modules/pipewire/

---

---

## System Restore Script Updates

The restore script has been updated to use the modern `realtime-privileges` package approach:

**File**: `~/projects/sys-restore-t14s-arch/restore/restore-system.sh`

### Changes Made in `install_music_production()`:

1. **Added package**: `realtime-privileges` to package list
   - Automatically configures RT limits via PAM
   - No manual `/etc/security/limits.d/audio.conf` needed

2. **Updated user group assignment**:
   ```bash
   sudo usermod -aG audio,realtime "$RESTORE_USER"
   ```
   - Adds user to both `audio` and `realtime` groups
   - Provides RT scheduling privileges automatically

3. **Removed manual audio.conf creation**:
   - Old approach: Manually creating `/etc/security/limits.d/audio.conf`
   - New approach: `realtime-privileges` package handles this via PAM
   - More maintainable and follows Arch best practices

### Packages Installed by Restore Script

**Music production function** (`install_music_production`):
```bash
yabridge yabridgectl wine-staging jack2 qpwgraph rtirq realtime-privileges
```

**Benefits**:
- ✅ Automatic RT limits configuration
- ✅ Proper PAM integration
- ✅ Updates with package manager
- ✅ No manual config file maintenance
- ✅ Works immediately after user logs back in

---

**Last updated**: 2025-11-27 15:00 PST
