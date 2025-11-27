# Audio Configuration for T14s

Low-latency PipeWire and WirePlumber configuration optimized for real-time audio work.

## Specs
- **Latency**: ~2.67ms (quantum=128 @ 48kHz)
- **Sample Rate**: 48kHz
- **Period Size**: 128 frames
- **Audio Card**: Family 17h/19h/1ah HD Audio Controller (Realtek ALC257)

## Installation

```bash
# Copy PipeWire config
mkdir -p ~/.config/pipewire/pipewire.conf.d
cp pipewire/99-lowlatency.conf ~/.config/pipewire/pipewire.conf.d/

# Copy WirePlumber config
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

## Troubleshooting

If you experience audio dropouts or glitches:
1. Increase quantum to 256 in `99-lowlatency.conf`
2. Increase period-size to 256 in `90-alsa-lowlatency.lua`
3. Check for CPU throttling or high system load
