# Audio Configuration

Low-latency audio configuration for PipeWire on ThinkPad T14s AMD Gen 1.

## Overview

Reduces audio latency from ~10.67ms (default) to ~2.67ms for real-time audio work and sample browsing.

## Files

### PipeWire Configuration

**`pipewire/99-lowlatency.conf`**
- Target: `~/.config/pipewire/pipewire.conf.d/99-lowlatency.conf`
- Sets quantum to 128 samples @ 48kHz (2.67ms latency)
- Configures realtime priority (nice=-11, rt.prio=88)
- Adjusts resampling quality

**Key settings:**
```conf
default.clock.quantum = 128      # 2.67ms latency @ 48kHz
default.clock.rate = 48000       # Sample rate
rt.prio = 88                     # Realtime priority
```

### WirePlumber Configuration

**`wireplumber/90-alsa-lowlatency.lua`**
- Target: `~/.config/wireplumber/main.lua.d/90-alsa-lowlatency.lua`
- ALSA period size reduced to 128 (from 1024)
- Disables batch mode for lower latency
- Specific settings for T14s audio controller (pci-0000_07_00.6)

**Key settings:**
```lua
api.alsa.period-size = 128       # Lower period for reduced latency
api.alsa.disable-batch = true    # Disable batch mode
audio.rate = 48000               # 48kHz for built-in audio
```

### ALSA Default Device

**`asoundrc`**
- Target: `~/.asoundrc`
- Routes ALSA through PipeWire
- Ensures compatibility with ALSA-only apps

### Audio Interrupt Priority

**`rtirq.conf`**
- Target: `/etc/rtirq.conf`
- Prioritizes audio interrupts for lower latency
- Requires `rtirq` package and `threadirqs` kernel parameter

**Priority list:**
```conf
RTIRQ_NAME_LIST="snd_hda_intel usb i8042"
RTIRQ_PRIO_HIGH=90
```

## Installation

Configs are automatically installed by the restore script:

```bash
./restore/restore-system.sh setup-audio
```

Or install manually:

```bash
mkdir -p ~/.config/pipewire/pipewire.conf.d
mkdir -p ~/.config/wireplumber/main.lua.d

cp pipewire/99-lowlatency.conf ~/.config/pipewire/pipewire.conf.d/
cp wireplumber/90-alsa-lowlatency.lua ~/.config/wireplumber/main.lua.d/
cp asoundrc ~/.asoundrc
sudo cp rtirq.conf /etc/rtirq.conf

systemctl --user restart pipewire pipewire-pulse wireplumber
```

## Verification

Check current quantum:

```bash
pw-metadata -n settings | grep clock.quantum
```

Expected output:
```
key:'clock.quantum' type:'Int32' value:'128'
```

## Customization

### Adjust Latency

Edit `pipewire/99-lowlatency.conf`:

| Quantum | Latency @ 48kHz | Use Case |
|---------|-----------------|----------|
| 64 | 1.33ms | Ultra-low (may cause xruns) |
| 128 | 2.67ms | **Low-latency (recommended)** |
| 256 | 5.33ms | Balanced |
| 512 | 10.67ms | Safe (default) |

### Change Sample Rate

Edit both configs:
- `pipewire/99-lowlatency.conf`: `default.clock.rate = 44100`
- `wireplumber/90-alsa-lowlatency.lua`: `audio.rate = 44100`

## Hardware-Specific Notes

**ThinkPad T14s AMD Gen 1:**
- Audio Controller: Family 17h/19h/1ah HD Audio (pci-0000_07_00.6)
- Default Profile: HiFi (Mic1, Mic2, Speaker)
- Works well with quantum=128 without xruns

**Requires:**
- `realtime-privileges` package (audio/realtime groups)
- `rtirq` for interrupt priority
- `threadirqs` kernel parameter

## Troubleshooting

### Audio crackling/stuttering
- Increase quantum (256 or 512)
- Check `dmesg` for "underrun" messages

### No sound
- Verify services running: `systemctl --user status pipewire`
- Check card profile: `pactl list cards`

### High CPU usage
- Reduce rt.prio (try 70-80)
- Increase quantum size

## References

- [PipeWire Wiki](https://gitlab.freedesktop.org/pipewire/pipewire/-/wikis/home)
- [WirePlumber Docs](https://pipewire.pages.freedesktop.org/wireplumber/)
- [Arch Wiki: PipeWire](https://wiki.archlinux.org/title/PipeWire)
- [Arch Wiki: Professional Audio](https://wiki.archlinux.org/title/Professional_audio)
