# Audio Configuration

Low-latency PipeWire and WirePlumber configuration optimized for real-time audio work.

## Specs
- **Latency**: ~2.67ms (quantum=128 @ 48kHz)
- **Sample Rate**: 48kHz
- **Period Size**: 128 frames
- **Audio Card**: Family 17h/19h/1ah HD Audio Controller (Realtek ALC257)

## Configuration

### 1. PipeWire Settings
**File**: `pipewire/99-lowlatency.conf`
- **Quantum**: 128 frames
- **Latency**: ~2.67ms @ 48kHz
- **RT priority**: 88

### 2. WirePlumber ALSA Settings
**File**: `wireplumber/90-alsa-lowlatency.lua`
- **Period size**: 128 frames
- **Batch mode**: disabled
- **Sample rate**: locked to 48kHz

## Installation

Automated install via restore script:
```bash
cd ../restore
./restore-system.sh setup-audio
```

Manual installation:
```bash
mkdir -p ~/.config/pipewire/pipewire.conf.d
cp pipewire/99-lowlatency.conf ~/.config/pipewire/pipewire.conf.d/

mkdir -p ~/.config/wireplumber/main.lua.d
cp wireplumber/90-alsa-lowlatency.lua ~/.config/wireplumber/main.lua.d/

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