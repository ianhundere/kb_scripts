# Restore Script Changes - Audio Configuration

**File**: `~/projects/sys-restore-t14s-arch/restore/restore-system.sh`  
**Date**: 2025-11-27

## New Function Added

### `setup_audio_lowlatency()`

**Location**: Lines 1126-1200 (after `setup_security()`)

**Purpose**: Configures low-latency PipeWire audio from backed-up configs

**Actions**:
1. Locates audio config directory: `../audio/` (relative to script)
2. Creates user config directories if missing:
   - `~/.config/pipewire/pipewire.conf.d/`
   - `~/.config/wireplumber/main.lua.d/`
3. Copies PipeWire config: `99-lowlatency.conf`
4. Copies WirePlumber config: `90-alsa-lowlatency.lua`
5. Creates `~/.asoundrc` for ALSA default device (if missing)
6. Sets audio card profile to HiFi mode
7. Restarts PipeWire services
8. Verifies quantum setting (should be 128)

**Dry-run support**: Yes ✓

## Integration Points

### 1. Added to `full_setup()` workflow
**Line**: 1226 (after `install_yay_and_aur`, before `setup_t14s_hardware`)

```bash
setup_audio_lowlatency
```

This ensures audio is configured automatically during full system restore.

### 2. Added to usage help
**Line**: 1271

```
setup-audio         Configure low-latency PipeWire audio (quantum=128, ~2.67ms latency)
```

### 3. Added to command router
**Line**: 1315

```bash
setup-audio) setup_audio_lowlatency ;;
```

## Usage Examples

### Standalone execution
```bash
cd ~/projects/sys-restore-t14s-arch/restore
./restore-system.sh setup-audio
```

### Part of full restore
```bash
./restore-system.sh full-setup
# Audio setup runs automatically
```

### Dry-run test
```bash
DRY_RUN=true ./restore-system.sh setup-audio
```

## Expected Output

**Success**:
```
Configuring Low-Latency Audio (PipeWire)...
✓ PipeWire low-latency config installed
✓ WirePlumber ALSA config installed
✓ ALSA default device configured
✓ Audio card set to HiFi profile
Restarting PipeWire services...
✓ Low-latency audio configured (quantum=128 @ 48kHz = ~2.67ms)
Audio configuration complete!
Note: Latency reduced from ~10.67ms to ~2.67ms
```

**Dry-run**:
```
Configuring Low-Latency Audio (PipeWire)...
[DRY RUN] Would install low-latency audio config
```

## Configuration Files Required

The function expects these files to exist:
```
~/projects/sys-restore-t14s-arch/audio/
├── pipewire/
│   └── 99-lowlatency.conf
└── wireplumber/
    └── 90-alsa-lowlatency.lua
```

If missing, function logs warning and returns error code 1.

## Next Steps

### For Allen & Heath Qu-Pac Integration

When configuring the Qu-Pac USB interface, consider:

1. **Create separate profile** for USB audio:
   - `~/projects/sys-restore-t14s-arch/audio/wireplumber/91-usb-audio-qupac.lua`
   - Prevent USB suspend: `["session.suspend-timeout-seconds"] = 0`
   - Optimize buffer for USB: may need larger buffer than 128 frames

2. **Pro-audio mode** may be needed:
   - Multi-channel routing (32×32 @ 48kHz)
   - Manual connection of channels
   - Use with `qpwgraph` or JACK tools

3. **Add Qu-Pac detection** to restore script:
   ```bash
   if lsusb | grep -q "Allen & Heath"; then
       setup_qupac_audio
   fi
   ```

## Testing Completed

- ✅ Syntax validation: `bash -n restore-system.sh`
- ✅ Dry-run test: `DRY_RUN=true ./restore-system.sh setup-audio`
- ✅ Help text displays correctly
- ✅ Function integrates into full_setup workflow

---

## Additional Changes: Realtime Privileges

### Updated `install_music_production()` Function

**Location**: Lines 485-552

**Changes**:

1. **Added `realtime-privileges` package** to install list:
   ```bash
   install_pkgs "music production" \
       yabridge yabridgectl wine-staging jack2 qpwgraph rtirq realtime-privileges
   ```

2. **Removed manual audio.conf creation**:
   - Old approach: Manually created `/etc/security/limits.d/audio.conf`
   - New approach: `realtime-privileges` package handles RT limits via PAM
   - More maintainable and follows Arch Linux best practices

3. **Updated user group assignment**:
   ```bash
   sudo usermod -aG audio,realtime "$RESTORE_USER"
   ```
   - Now adds user to both `audio` and `realtime` groups
   - Required for `realtime-privileges` package to grant RT scheduling

4. **Added explanatory comments** about the package-based approach

### Benefits

- ✅ **Automatic configuration**: RT limits configured via PAM, no manual files
- ✅ **Package manager integration**: Updates handled by pacman
- ✅ **Best practices**: Follows Arch Linux pro-audio group standards
- ✅ **Cleaner code**: Removed manual config file creation
- ✅ **More reliable**: PAM integration ensures privileges work correctly

### Verification After Restore

After running `./restore-system.sh install-music`, verify with:

```bash
# Check user groups
groups | grep -E "audio|realtime"

# Check RT limits (after logout/login)
ulimit -r      # Should be 95
ulimit -l      # Should be unlimited

# Check PipeWire RT scheduling
ps -eLo pid,tid,class,rtprio,comm | grep pipewire
# Should show FIFO realtime thread
```

---

**Last updated**: 2025-11-27 15:00 PST
