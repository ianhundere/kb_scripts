#!/bin/bash
# System restoration for ThinkPad T14s AMD Gen 1 (Arch Linux + KDE Plasma)
# Automated backup restoration, package installation, and hardware configuration
# hardware reference: https://wiki.archlinux.org/title/Lenovo_ThinkPad_T14s_(AMD)_Gen_1

set -e

# --- CONFIGURATION ---
BORG_REPO="${BORG_REPO}"
RESTORE_USER="${RESTORE_USER:-$USER}"
DRY_RUN="${DRY_RUN:-false}"

# Logging
LOG_FILE="${HOME}/restore-system.log"
exec > >(tee -a "$LOG_FILE") 2>&1

# --- COLORS ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# --- HELPERS ---
print_msg() { echo -e "${1}${@:2}${NC}"; }

log_error() {
    print_msg "$RED" "ERROR: $1"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1" >> "$LOG_FILE"
}

log_warning() {
    print_msg "$YELLOW" "WARNING: $1"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1" >> "$LOG_FILE"
}

check_passphrase() {
    if [[ -z "$BORG_REPO" ]]; then
        log_error "BORG_REPO not set."
        echo "Run: export BORG_REPO='user@host:repo'"
        exit 1
    fi
    if [[ -z "$BORG_PASSPHRASE" ]]; then
        log_error "BORG_PASSPHRASE not set."
        echo "Run: export BORG_PASSPHRASE='your-passphrase'"
        exit 1
    fi
}

get_latest_archive() {
    local archive=$(borg list "$BORG_REPO" --last 1 --short 2>/dev/null | tail -1)
    if [[ -z "$archive" ]]; then
        log_error "No backups found in repository: $BORG_REPO"
        exit 1
    fi
    echo "$archive"
}

cleanup_temp() {
    local temp_dir="$1"
    [[ -n "$temp_dir" && -d "$temp_dir" ]] && rm -rf "$temp_dir"
}

wait_for_process_exit() {
    local process_name="$1"
    local max_wait="${2:-10}"

    for i in $(seq 1 $max_wait); do
        if ! pgrep "$process_name" >/dev/null 2>&1; then
            return 0
        fi
        sleep 1
    done

    log_warning "$process_name still running after ${max_wait}s"
    return 1
}

safe_extract() {
    local repo="$1"
    local archive="$2"
    shift 2
    local paths=("$@")

    if [[ "$DRY_RUN" = "true" ]]; then
        print_msg "$BLUE" "[DRY RUN] Would extract: ${paths[*]}"
        return 0
    fi

    for path in "${paths[@]}"; do
        if borg extract "$repo::$archive" "$path" 2>/dev/null; then
            print_msg "$GREEN" "✓ Extracted: $path"
        else
            log_warning "Could not extract: $path (may not exist in backup)"
        fi
    done
}

# dry run wrapper - executes command only if not in dry run mode
run_cmd() {
    local desc="$1"
    shift

    if [[ "$DRY_RUN" = "true" ]]; then
        print_msg "$BLUE" "[DRY RUN] $desc"
        return 0
    fi

    "$@"
}

# copy file or directory from backup extraction to home
copy_if_exists() {
    local src="home/$RESTORE_USER/$1"
    local dest="${2:-~/$1}"

    if [[ -d "$src" ]]; then
        rsync -av "$src/" "$dest/" 2>/dev/null || true
    elif [[ -f "$src" ]]; then
        mkdir -p "$(dirname "$dest")"
        cp "$src" "$dest" 2>/dev/null || true
    fi
}

# install packages with dry run support
install_pkgs() {
    local desc="$1"
    shift
    local pkgs=("$@")

    if [[ "$DRY_RUN" = "true" ]]; then
        print_msg "$BLUE" "[DRY RUN] Would install $desc: ${pkgs[*]}"
        return 0
    fi

    sudo pacman -S --needed --noconfirm "${pkgs[@]}"
}

# --- RESTORE FUNCTIONS ---

restore_shell_config() {
    print_msg "$BLUE" "Restoring Shell (zsh/p10k)..."
    check_passphrase

    local archive=$(get_latest_archive)
    local temp_dir=$(mktemp -d)
    trap "cleanup_temp '$temp_dir'" RETURN
    cd "$temp_dir"

    safe_extract "$BORG_REPO" "$archive" \
        "home/$RESTORE_USER/.zshrc" \
        "home/$RESTORE_USER/.zsh_history" \
        "home/$RESTORE_USER/.p10k.zsh" \
        "home/$RESTORE_USER/powerlevel10k"

    # copy files if exist
    copy_if_exists ".zshrc"
    copy_if_exists ".p10k.zsh"
    copy_if_exists ".zsh_history"
    copy_if_exists "powerlevel10k"

    # install autosuggestions if missing
    if ! pacman -Qi zsh-autosuggestions &> /dev/null; then
        run_cmd "would install zsh-autosuggestions" \
            sudo pacman -S --needed --noconfirm zsh-autosuggestions
    fi

    print_msg "$GREEN" "Shell restored!"
}

restore_kde_config() {
    print_msg "$BLUE" "Restoring KDE Configuration & Data..."
    check_passphrase

    local archive=$(get_latest_archive)
    local temp_dir=$(mktemp -d)
    trap "cleanup_temp '$temp_dir'" RETURN
    cd "$temp_dir"

    # Critical KDE Files
    local kde_files=(
        "home/$RESTORE_USER/.config/plasma-org.kde.plasma.desktop-appletsrc"
        "home/$RESTORE_USER/.config/plasmashellrc"
        "home/$RESTORE_USER/.config/kdeglobals"
        "home/$RESTORE_USER/.config/kwinrc"
        "home/$RESTORE_USER/.config/kglobalshortcutsrc"
        "home/$RESTORE_USER/.config/dolphinrc"
        "home/$RESTORE_USER/.config/konsolerc"
        "home/$RESTORE_USER/.local/share/kwalletd"
        "home/$RESTORE_USER/.local/share/plasma"
    )

    safe_extract "$BORG_REPO" "$archive" "${kde_files[@]}"

    if [[ "$DRY_RUN" = "true" ]]; then
        print_msg "$BLUE" "[DRY RUN] Would stop Plasma and copy configs"
        return 0
    fi

    print_msg "$YELLOW" "Stopping Plasma..."
    kquitapp6 plasmashell 2>/dev/null || killall plasmashell 2>/dev/null || true

    wait_for_process_exit "plasmashell" 10

    # Copy configs
    if [[ -d "home/$RESTORE_USER/.config" ]]; then
        cp -r "home/$RESTORE_USER/.config/"* ~/.config/ 2>/dev/null || true
    fi

    if [[ -d "home/$RESTORE_USER/.local/share" ]]; then
        [[ -d ~/.local/share ]] || mkdir -p ~/.local/share
        cp -r "home/$RESTORE_USER/.local/share/"* ~/.local/share/ 2>/dev/null || true
    fi

    print_msg "$GREEN" "KDE restored! Restarting Plasma..."
    (kstart6 plasmashell > /dev/null 2>&1 &)
}

restore_misc_configs() {
    print_msg "$BLUE" "Restoring Git, SSH, GPG, Dev Environments..."
    check_passphrase

    local archive=$(get_latest_archive)
    local temp_dir=$(mktemp -d)
    trap "cleanup_temp '$temp_dir'" RETURN
    cd "$temp_dir"

    safe_extract "$BORG_REPO" "$archive" \
        "home/$RESTORE_USER/.gitconfig" \
        "home/$RESTORE_USER/.ssh/config" \
        "home/$RESTORE_USER/.gnupg" \
        "home/$RESTORE_USER/.docker" \
        "home/$RESTORE_USER/.kube" \
        "home/$RESTORE_USER/.pyenv" \
        "home/$RESTORE_USER/.nvm" \
        "home/$RESTORE_USER/.npm" \
        "home/$RESTORE_USER/.arduino15" \
        "home/$RESTORE_USER/.mozilla" \
        "home/$RESTORE_USER/.config/systemd"

    if [[ "$DRY_RUN" = "true" ]]; then
        print_msg "$BLUE" "[DRY RUN] Would copy git/ssh/gpg/dev configs"
        return 0
    fi

    [[ -f "home/$RESTORE_USER/.gitconfig" ]] && cp "home/$RESTORE_USER/.gitconfig" ~/

    if [[ -f "home/$RESTORE_USER/.ssh/config" ]]; then
        [[ -d ~/.ssh ]] || mkdir -p ~/.ssh
        cp "home/$RESTORE_USER/.ssh/config" ~/.ssh/
        chmod 600 ~/.ssh/config
    fi

    if [[ -d "home/$RESTORE_USER/.gnupg" ]]; then
        [[ -d ~/.gnupg ]] && mv ~/.gnupg ~/.gnupg.bak.$(date +%s)
        cp -r "home/$RESTORE_USER/.gnupg" ~/
        chmod 700 ~/.gnupg
    fi

    # Dev environments
    [[ -d "home/$RESTORE_USER/.docker" ]] && cp -r "home/$RESTORE_USER/.docker" ~/
    [[ -d "home/$RESTORE_USER/.kube" ]] && cp -r "home/$RESTORE_USER/.kube" ~/
    [[ -d "home/$RESTORE_USER/.pyenv" ]] && rsync -av "home/$RESTORE_USER/.pyenv/" ~/.pyenv/
    [[ -d "home/$RESTORE_USER/.nvm" ]] && rsync -av "home/$RESTORE_USER/.nvm/" ~/.nvm/
    [[ -d "home/$RESTORE_USER/.npm" ]] && rsync -av "home/$RESTORE_USER/.npm/" ~/.npm/
    [[ -d "home/$RESTORE_USER/.arduino15" ]] && rsync -av "home/$RESTORE_USER/.arduino15/" ~/.arduino15/
    [[ -d "home/$RESTORE_USER/.mozilla" ]] && rsync -av "home/$RESTORE_USER/.mozilla/" ~/.mozilla/

    # Systemd user services
    if [[ -d "home/$RESTORE_USER/.config/systemd" ]]; then
        mkdir -p ~/.config/systemd
        cp -r "home/$RESTORE_USER/.config/systemd/"* ~/.config/systemd/
        print_msg "$YELLOW" "Restored systemd user services (protonvpn_reconnect, etc.)"
    fi

    print_msg "$GREEN" "Misc configs & dev environments restored!"
}

restore_data() {
    print_msg "$BLUE" "Restoring User Data (bin, Documents, projects, etc.)..."
    check_passphrase

    local archive=$(get_latest_archive)
    local temp_dir=$(mktemp -d)
    trap "cleanup_temp '$temp_dir'" RETURN
    cd "$temp_dir"

    local data_dirs=(
        "home/$RESTORE_USER/bin"
        "home/$RESTORE_USER/Desktop"
        "home/$RESTORE_USER/Documents"
        "home/$RESTORE_USER/Downloads"
        "home/$RESTORE_USER/projects"
        "home/$RESTORE_USER/music-projects"
        "home/$RESTORE_USER/Calibre Library"
        "home/$RESTORE_USER/notes"
        "home/$RESTORE_USER/go"
        "home/$RESTORE_USER/Arduino"
        "home/$RESTORE_USER/Sync"
        "home/$RESTORE_USER/Videos"
        "home/$RESTORE_USER/Screenshots"
        "home/$RESTORE_USER/Screencasts"
        "home/$RESTORE_USER/Bitwig Studio"
        "home/$RESTORE_USER/new-wineprefix"
    )

    print_msg "$YELLOW" "Extracting data directories (may take a while)..."

    if [[ "$DRY_RUN" = "true" ]]; then
        print_msg "$BLUE" "[DRY RUN] Would extract: ${data_dirs[*]}"
        return 0
    fi

    for dir in "${data_dirs[@]}"; do
        if borg extract --progress "$BORG_REPO::$archive" "$dir" 2>/dev/null; then
            print_msg "$GREEN" "✓ Extracted: $dir"
        else
            log_warning "Could not extract: $dir"
        fi
    done

    print_msg "$BLUE" "Copying data to home directory..."

    # Function to safely move directories
    move_if_exists() {
        if [[ -d "home/$RESTORE_USER/$1" ]]; then
            rsync -av "home/$RESTORE_USER/$1/" ~/"$1"/
        fi
    }

    move_if_exists "bin"
    move_if_exists "Desktop"
    move_if_exists "Documents"
    move_if_exists "Downloads"
    move_if_exists "projects"
    move_if_exists "music-projects"
    move_if_exists "Calibre Library"
    move_if_exists "notes"
    move_if_exists "go"
    move_if_exists "Arduino"
    move_if_exists "Sync"
    move_if_exists "Videos"
    move_if_exists "Screenshots"
    move_if_exists "Screencasts"
    move_if_exists "Bitwig Studio"
    move_if_exists "new-wineprefix"

    # Create performance toggle scripts
    if [[ "$DRY_RUN" != "true" ]]; then
        mkdir -p ~/bin

        cat > ~/bin/perf-mode <<'PERFEOF'
#!/bin/bash
# set cpu governor to performance mode
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor > /dev/null
echo "performance mode enabled"
PERFEOF

        cat > ~/bin/battery-mode <<'BATEOF'
#!/bin/bash
# set cpu governor to powersave mode
echo powersave | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor > /dev/null
echo "battery mode enabled"
BATEOF

        print_msg "$GREEN" "✓ created performance toggle scripts"
    fi

    # Make bin scripts executable
    if [[ -d ~/bin ]]; then
        chmod +x ~/bin/* 2>/dev/null || true
    fi

    print_msg "$GREEN" "User data restored!"
}

restore_app_configs() {
    print_msg "$BLUE" "Restoring Application Configs (Calibre, Obsidian, Syncthing, VS Code)..."
    check_passphrase

    local archive=$(get_latest_archive)
    local temp_dir=$(mktemp -d)
    trap "cleanup_temp '$temp_dir'" RETURN
    cd "$temp_dir"

    local app_configs=(
        "home/$RESTORE_USER/.config/calibre"
        "home/$RESTORE_USER/.config/obsidian"
        "home/$RESTORE_USER/.config/syncthing"
        "home/$RESTORE_USER/.config/Code"
        "home/$RESTORE_USER/.config/vscode-mssql"
        "home/$RESTORE_USER/.config/vscode-sqltools"
    )

    safe_extract "$BORG_REPO" "$archive" "${app_configs[@]}"

    if [[ "$DRY_RUN" = "true" ]]; then
        print_msg "$BLUE" "[DRY RUN] Would copy application configs"
        return 0
    fi

    # Copy configs if they exist
    for config in calibre obsidian syncthing Code vscode-mssql vscode-sqltools; do
        if [[ -d "home/$RESTORE_USER/.config/$config" ]]; then
            mkdir -p ~/.config/
            cp -r "home/$RESTORE_USER/.config/$config" ~/.config/
            print_msg "$GREEN" "✓ Restored: $config config"
        fi
    done

    print_msg "$GREEN" "Application configs restored!"
}

# --- INSTALL FUNCTIONS ---

install_base_tools() {
    print_msg "$BLUE" "installing base/dev tools..."
    install_pkgs "base/dev tools" \
        base-devel git vim curl wget rsync less \
        traceroute inetutils tcpdump net-tools bind nmap \
        clamav htop btop tree ripgrep fd bat fzf jq yq \
        openssh borg ufw rkhunter
}

install_lean_kde() {
    print_msg "$BLUE" "installing lean kde..."
    install_pkgs "lean kde" \
        plasma-meta plasma-workspace \
        dolphin konsole kate ark gwenview spectacle okular kcalc \
        kwalletmanager ffmpegthumbs \
        xdg-utils bluez-utils cups \
        zsh-completions
}

install_desktop_apps() {
    print_msg "$BLUE" "installing desktop apps & audio..."
    install_pkgs "desktop apps" \
        firefox chromium code obsidian bitwarden signal-desktop \
        calibre syncthing discord audacity steam \
        pipewire pipewire-alsa pipewire-pulse pipewire-jack \
        wireplumber pavucontrol alsa-utils vlc \
        libreoffice-fresh gimp inkscape kdenlive obs-studio
}

install_music_production() {
    print_msg "$BLUE" "installing music production stack..."
    install_pkgs "music production" \
        yabridge yabridgectl wine-staging jack2 qjackctl rtirq

    # audio realtime limits (fixes yabridge memlock warning)
    run_cmd "would configure audio realtime limits" \
        sudo tee /etc/security/limits.d/audio.conf > /dev/null <<'EOF'
# Audio realtime limits for yabridge and audio production
@audio   -  rtprio     95
@audio   -  memlock    unlimited
@audio   -  nice      -19
EOF

    # Add user to audio group
    sudo usermod -aG audio $RESTORE_USER

    # Configure rtirq for audio interrupt priority
    run_cmd "would configure rtirq for audio priority" \
        sudo tee /etc/rtirq.conf > /dev/null <<'EOF'
# Audio interrupt priority configuration
RTIRQ_NAME_LIST="snd_hda_intel usb i8042"
RTIRQ_PRIO_HIGH=90
RTIRQ_PRIO_DECR=5
RTIRQ_RESET_ALL=0
EOF

    # Enable rtirq service
    if [[ "$DRY_RUN" != "true" ]]; then
        sudo systemctl enable --now rtirq 2>/dev/null || true
    fi

    # Add threadirqs kernel parameter (required for rtirq to work)
    if [[ -d /boot/loader/entries ]]; then
        # systemd-boot detected
        for entry in /boot/loader/entries/arch*.conf; do
            if [[ -f "$entry" ]] && ! grep -q "threadirqs" "$entry" 2>/dev/null; then
                if [[ "$DRY_RUN" = "true" ]]; then
                    print_msg "$BLUE" "[DRY RUN] Would add threadirqs to $entry"
                else
                    sudo sed -i 's/options /options threadirqs /' "$entry"
                    print_msg "$GREEN" "✓ added threadirqs to $(basename $entry)"
                fi
            fi
        done
        if [[ "$DRY_RUN" != "true" ]]; then
            print_msg "$YELLOW" "note: reboot required for threadirqs to take effect"
        fi
    elif [[ -f /etc/default/grub ]]; then
        # GRUB detected
        if ! grep -q "threadirqs" /etc/default/grub 2>/dev/null; then
            if [[ "$DRY_RUN" = "true" ]]; then
                print_msg "$BLUE" "[DRY RUN] Would add threadirqs to GRUB"
            else
                sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/&threadirqs /' /etc/default/grub
                sudo grub-mkconfig -o /boot/grub/grub.cfg
                print_msg "$GREEN" "✓ added threadirqs to GRUB"
                print_msg "$YELLOW" "note: reboot required for threadirqs to take effect"
            fi
        fi
    fi

    # Fix application icons for KDE Wayland/X11
    # Signal (Wayland): Desktop File Name must match - need signal.desktop not signal-desktop.desktop
    # Bitwig (X11): StartupWMClass must match Java class name
    if [[ -d ~/.local/share/applications ]] || [[ "$DRY_RUN" = "true" ]]; then
        if [[ "$DRY_RUN" = "true" ]]; then
            print_msg "$BLUE" "[DRY RUN] Would create Signal/Bitwig desktop file fixes"
        else
            mkdir -p ~/.local/share/applications

            # Signal desktop file fix (Wayland)
            cat > ~/.local/share/applications/signal.desktop <<'EOF'
[Desktop Entry]
Type=Application
Name=Signal
Comment=Signal - Private Messenger
Icon=signal-desktop
Exec=signal-desktop -- %u
Terminal=false
Categories=Network;InstantMessaging;
StartupWMClass=signal
MimeType=x-scheme-handler/sgnl;x-scheme-handler/signalcaptcha;
Keywords=sgnl;chat;im;messaging;messenger;security;privat;
X-GNOME-UsesNotifications=true
EOF

            # Bitwig Studio desktop file fix (X11) - handles both beta and stable
            if command -v bitwig-studio-beta &>/dev/null; then
                cat > ~/.local/share/applications/com.bitwig.BitwigStudioBeta.desktop <<'EOF'
[Desktop Entry]
Version=1.5
Type=Application
Name=Bitwig Studio Beta
GenericName=Digital Audio Workstation
Comment=Modern music production and performance
Icon=com.bitwig.BitwigStudioBeta
Exec=bitwig-studio-beta
Terminal=false
MimeType=application/bitwig-beta-clip;application/bitwig-beta-device;application/bitwig-beta-package;application/bitwig-beta-preset;application/bitwig-beta-project;application/bitwig-beta-scene;application/bitwig-beta-template;application/bitwig-beta-extension;application/bitwig-beta-remote-controls;application/bitwig-beta-module;application/bitwig-beta-modulator;application/vnd.bitwig.dawproject
Categories=AudioVideo;Music;Audio;Sequencer;Midi;Mixer;Player;Recorder
Keywords=daw;bitwig;audio;midi
StartupNotify=true
StartupWMClass=com.bitwig.BitwigStudio
EOF
                print_msg "$GREEN" "✓ Bitwig Studio Beta desktop file created (fixes X11 icon)"
            elif command -v bitwig-studio &>/dev/null; then
                cat > ~/.local/share/applications/com.bitwig.BitwigStudio.desktop <<'EOF'
[Desktop Entry]
Version=1.5
Type=Application
Name=Bitwig Studio
GenericName=Digital Audio Workstation
Comment=Modern music production and performance
Icon=com.bitwig.BitwigStudio
Exec=bitwig-studio
Terminal=false
MimeType=application/bitwig-clip;application/bitwig-device;application/bitwig-package;application/bitwig-preset;application/bitwig-project;application/bitwig-scene;application/bitwig-template;application/bitwig-extension;application/bitwig-remote-controls;application/bitwig-module;application/bitwig-modulator;application/vnd.bitwig.dawproject
Categories=AudioVideo;Music;Audio;Sequencer;Midi;Mixer;Player;Recorder
Keywords=daw;bitwig;audio;midi
StartupNotify=true
StartupWMClass=com.bitwig.BitwigStudio
EOF
                print_msg "$GREEN" "✓ Bitwig Studio desktop file created (fixes X11 icon)"
            fi

            update-desktop-database ~/.local/share/applications/ 2>/dev/null || true
            print_msg "$GREEN" "✓ Signal desktop file created (fixes Wayland icon)"
        fi
    fi

    print_msg "$GREEN" "Music production tools installed!"
    print_msg "$YELLOW" "Note: Log out and back in for audio group to take effect"
}

restore_music_production() {
    print_msg "$BLUE" "Restoring Music Production Config..."
    check_passphrase

    local archive=$(get_latest_archive)
    local temp_dir=$(mktemp -d)
    trap "cleanup_temp '$temp_dir'" RETURN
    cd "$temp_dir"

    local music_files=(
        "home/$RESTORE_USER/.BitwigStudio"
        "home/$RESTORE_USER/.wine"
        "home/$RESTORE_USER/.vst"
        "home/$RESTORE_USER/.vst3"
        "home/$RESTORE_USER/.clap"
        "home/$RESTORE_USER/.config/yabridgectl"
        "home/$RESTORE_USER/.config/pipewire"
        "home/$RESTORE_USER/.config/wireplumber"
        "home/$RESTORE_USER/.config/beets"
        "home/$RESTORE_USER/.config/htop"
        "home/$RESTORE_USER/.config/cheat"
        "home/$RESTORE_USER/.config/REAPER"
        "home/$RESTORE_USER/.config/gh"
        "home/$RESTORE_USER/.config/helm"
        "home/$RESTORE_USER/.local/share/fonts"
    )

    print_msg "$YELLOW" "This may take a while (Bitwig + Wine prefix ~11GB)..."

    if [[ "$DRY_RUN" = "true" ]]; then
        print_msg "$BLUE" "[DRY RUN] Would extract music production files"
        return 0
    fi

    for file in "${music_files[@]}"; do
        if borg extract --progress "$BORG_REPO::$archive" "$file" 2>/dev/null; then
            print_msg "$GREEN" "✓ Extracted: $file"
        else
            log_warning "Could not extract: $file"
        fi
    done

    print_msg "$BLUE" "Copying music production files..."

    # Copy configs
    [[ -d "home/$RESTORE_USER/.config/yabridgectl" ]] && cp -r "home/$RESTORE_USER/.config/yabridgectl" ~/.config/
    [[ -d "home/$RESTORE_USER/.config/wireplumber" ]] && cp -r "home/$RESTORE_USER/.config/wireplumber" ~/.config/
    [[ -d "home/$RESTORE_USER/.config/pipewire" ]] && cp -r "home/$RESTORE_USER/.config/pipewire" ~/.config/
    [[ -d "home/$RESTORE_USER/.config/beets" ]] && cp -r "home/$RESTORE_USER/.config/beets" ~/.config/
    [[ -d "home/$RESTORE_USER/.config/htop" ]] && cp -r "home/$RESTORE_USER/.config/htop" ~/.config/
    [[ -d "home/$RESTORE_USER/.config/cheat" ]] && cp -r "home/$RESTORE_USER/.config/cheat" ~/.config/
    [[ -d "home/$RESTORE_USER/.config/REAPER" ]] && cp -r "home/$RESTORE_USER/.config/REAPER" ~/.config/
    [[ -d "home/$RESTORE_USER/.config/gh" ]] && cp -r "home/$RESTORE_USER/.config/gh" ~/.config/
    [[ -d "home/$RESTORE_USER/.config/helm" ]] && cp -r "home/$RESTORE_USER/.config/helm" ~/.config/

    # Copy plugins & DAW
    [[ -d "home/$RESTORE_USER/.BitwigStudio" ]] && rsync -av "home/$RESTORE_USER/.BitwigStudio/" ~/.BitwigStudio/
    [[ -d "home/$RESTORE_USER/.wine" ]] && rsync -av "home/$RESTORE_USER/.wine/" ~/.wine/
    [[ -d "home/$RESTORE_USER/.vst" ]] && rsync -av "home/$RESTORE_USER/.vst/" ~/.vst/
    [[ -d "home/$RESTORE_USER/.vst3" ]] && rsync -av "home/$RESTORE_USER/.vst3/" ~/.vst3/
    [[ -d "home/$RESTORE_USER/.clap" ]] && rsync -av "home/$RESTORE_USER/.clap/" ~/.clap/

    # Copy fonts
    [[ -d "home/$RESTORE_USER/.local/share/fonts" ]] && rsync -av "home/$RESTORE_USER/.local/share/fonts/" ~/.local/share/fonts/
    fc-cache -fv ~/.local/share/fonts 2>/dev/null || true

    # Sync yabridge plugins
    if command -v yabridgectl &>/dev/null; then
        print_msg "$BLUE" "Syncing yabridge plugins..."
        yabridgectl sync
        print_msg "$GREEN" "Yabridge plugins synced!"
    fi

    print_msg "$GREEN" "Music production environment restored!"
}

install_yay_and_aur() {
    print_msg "$BLUE" "Installing AUR Packages..."

    if ! command -v yay &> /dev/null; then
        if [[ "$DRY_RUN" = "true" ]]; then
            print_msg "$BLUE" "[DRY RUN] Would install yay"
        else
            local temp_dir=$(mktemp -d)
            trap "cd ~; rm -rf '$temp_dir'" EXIT ERR
            cd "$temp_dir"
            git clone https://aur.archlinux.org/yay.git
            cd yay
            makepkg -si --noconfirm
            cd ~ && rm -rf "$temp_dir"
        fi
    fi

    local aur_pkgs=(
        mission-center
        tlpui
        thinkfan
        flux-bin
        clamtk
        python-llfuse
        bitwig-studio-beta
        ocenaudio-bin
        sononym
    )

    if [[ "$DRY_RUN" = "true" ]]; then
        print_msg "$BLUE" "[DRY RUN] Would install AUR packages: ${aur_pkgs[*]}"
        return 0
    fi

    yay -S --needed --noconfirm "${aur_pkgs[@]}"
}

# --- HARDWARE SETUP ---

setup_t14s_hardware() {
    print_msg "$BLUE" "Configuring T14s Hardware (Video/Fingerprint/Keyboard)..."

    local pkgs=(
        tlp tlp-rdw acpi_call smartmontools
        amd-ucode vulkan-radeon xf86-video-amdgpu mesa-demos sof-firmware
        fprintd libfprint iwd networkmanager network-manager-applet wireless_tools
        fwupd keyd zram-generator
    )

    if [[ "$DRY_RUN" = "true" ]]; then
        print_msg "$BLUE" "[DRY RUN] Would install hardware packages and configure keyd"
        return 0
    fi

    sudo pacman -S --needed --noconfirm "${pkgs[@]}"

    # Services
    sudo systemctl enable --now fprintd keyd

    # Keyboard Remap (Backspace <-> Backslash) - only if not already configured
    sudo mkdir -p /etc/keyd

    if [[ ! -f /etc/keyd/default.conf ]]; then
        sudo tee /etc/keyd/default.conf > /dev/null <<'EOF'
[ids]
*
0001:0001
[main]
backspace = backslash
backslash = backspace
EOF
        sudo systemctl restart keyd
    else
        print_msg "$YELLOW" "keyd config already exists, skipping..."
    fi

    print_msg "$GREEN" "Hardware drivers installed."
}

setup_t14s_power() {
    print_msg "$BLUE" "Configuring T14s Power (TLP & Thinkfan)..."

    # 1. Enable Kernel Fan Control
    if [[ ! -f /etc/modprobe.d/thinkpad_acpi.conf ]]; then
        if [[ "$DRY_RUN" = "true" ]]; then
            print_msg "$BLUE" "[DRY RUN] Would configure thinkpad_acpi fan control"
        else
            echo "options thinkpad_acpi fan_control=1" | sudo tee /etc/modprobe.d/thinkpad_acpi.conf
            sudo modprobe -r thinkpad_acpi 2>/dev/null || true
            sudo modprobe thinkpad_acpi 2>/dev/null || true
        fi
    fi

    # 2. ZRAM Config
    if [[ ! -f /etc/systemd/zram-generator.conf ]]; then
        if [[ "$DRY_RUN" = "true" ]]; then
            print_msg "$BLUE" "[DRY RUN] Would configure ZRAM"
        else
            print_msg "$YELLOW" "Configuring ZRAM..."
            sudo tee /etc/systemd/zram-generator.conf > /dev/null <<EOF
[zram0]
zram-size = min(ram, 8192)
compression-algorithm = zstd
EOF
        fi
    fi

    # 3. swappiness configuration (audio optimization)
    if [[ ! -f /etc/sysctl.d/99-swappiness.conf ]]; then
        if [[ "$DRY_RUN" = "true" ]]; then
            print_msg "$BLUE" "[DRY RUN] Would configure swappiness"
        else
            echo "vm.swappiness=10" | sudo tee /etc/sysctl.d/99-swappiness.conf > /dev/null
            sudo sysctl -p /etc/sysctl.d/99-swappiness.conf 2>/dev/null || true
            print_msg "$GREEN" "✓ swappiness set to 10"
        fi
    fi

    # 4. TLP Configuration (Embedded - T14s optimized)
    if [[ "$DRY_RUN" = "true" ]]; then
        print_msg "$BLUE" "[DRY RUN] Would configure TLP and Thinkfan"
        return 0
    fi

    if [[ -f /etc/tlp.conf ]]; then
        sudo mv /etc/tlp.conf /etc/tlp.conf.bak.$(date +%s)
    fi
    print_msg "$YELLOW" "Installing optimized TLP config..."
    sudo tee /etc/tlp.conf > /dev/null <<'TLPEOF'
# TLP Configuration for ThinkPad T14s AMD Gen 1
# Optimized for battery life and thermal management

TLP_ENABLE=1
TLP_DEFAULT_MODE=BAT

CPU_DRIVER_OPMODE_ON_AC=active
CPU_DRIVER_OPMODE_ON_BAT=active

CPU_SCALING_GOVERNOR_ON_AC=powersave
CPU_SCALING_GOVERNOR_ON_BAT=powersave

CPU_ENERGY_PERF_POLICY_ON_AC=balance_performance
CPU_ENERGY_PERF_POLICY_ON_BAT=power

CPU_BOOST_ON_AC=1
CPU_BOOST_ON_BAT=0

CPU_HWP_DYN_BOOST_ON_AC=1
CPU_HWP_DYN_BOOST_ON_BAT=0

SCHED_POWERSAVE_ON_AC=0
SCHED_POWERSAVE_ON_BAT=1

NMI_WATCHDOG=0

PLATFORM_PROFILE_ON_AC=performance
PLATFORM_PROFILE_ON_BAT=balanced

DISK_IDLE_SECS_ON_AC=0
DISK_IDLE_SECS_ON_BAT=2

MAX_LOST_WORK_SECS_ON_AC=15
MAX_LOST_WORK_SECS_ON_BAT=15

WIFI_PWR_ON_AC=off
WIFI_PWR_ON_BAT=on

WOL_DISABLE=Y

SOUND_POWER_SAVE_ON_AC=0
SOUND_POWER_SAVE_ON_BAT=1

PCIE_ASPM_ON_AC=default
PCIE_ASPM_ON_BAT=powersupersave

RUNTIME_PM_ON_AC=on
RUNTIME_PM_ON_BAT=auto

USB_AUTOSUSPEND=1
USB_DENYLIST="04f2:b67c 8087:0026"
USB_EXCLUDE_BTUSB=1
USB_EXCLUDE_PHONE=1

RESTORE_DEVICE_STATE_ON_STARTUP=0

DEVICES_TO_DISABLE_ON_STARTUP="bluetooth wwan nfc"
DEVICES_TO_ENABLE_ON_STARTUP="wifi"

DEVICES_TO_DISABLE_ON_BAT_NOT_IN_USE="bluetooth wwan nfc"

START_CHARGE_THRESH_BAT0=40
STOP_CHARGE_THRESH_BAT0=80

RESTORE_THRESHOLDS_ON_BAT=1

NATACPI_ENABLE=1
TPACPI_ENABLE=1
TPSMAPI_ENABLE=1
TLPEOF

    # 5. Thinkfan Configuration (Embedded - T14s AMD optimized)
    if [[ -f /etc/thinkfan.yaml ]]; then
        sudo mv /etc/thinkfan.yaml /etc/thinkfan.yaml.bak.$(date +%s)
    fi
    print_msg "$YELLOW" "Installing optimized Thinkfan config..."
    sudo tee /etc/thinkfan.yaml > /dev/null <<'THINKFANEOF'
sensors:
  - hwmon: /sys/devices/platform/thinkpad_hwmon/hwmon
    indices: [1, 3, 4, 5, 6, 7]
  - hwmon: /sys/devices/platform/coretemp.0/hwmon
    indices: [1, 2, 3, 4, 5, 6, 7, 8, 10, 11]
  - tpacpi: /proc/acpi/ibm/thermal
    indices: [1, 2, 3, 4]
    max_errors: 10

fans:
  - tpacpi: /proc/acpi/ibm/fan
    max_errors: 10

levels:
  - [0, 0, 45]
  - [1, 39, 52]
  - [2, 51, 55]
  - [3, 54, 58]
  - [4, 56, 66]
  - [5, 64, 70]
  - [6, 68, 80]
  - [7, 79, 86]
  - ["level auto", 54, 75]
  - ["level disengaged", 70, 255]
THINKFANEOF

    # 6. amd p-state driver check (optional - better for ryzen mobile)
    if ! grep -q "amd_pstate=active" /etc/default/grub 2>/dev/null; then
        print_msg "$YELLOW" "note: amd_pstate not configured"
        print_msg "$BLUE" "run: sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT=\"/&amd_pstate=active /' /etc/default/grub"
        print_msg "$BLUE" "then: sudo grub-mkconfig -o /boot/grub/grub.cfg && reboot"
    else
        print_msg "$GREEN" "✓ amd p-state configured"
    fi

    # 7. Enable Services
    sudo systemctl enable --now tlp
    sudo systemctl enable --now thinkfan

    print_msg "$GREEN" "Power management optimized!"
}

setup_security() {
    print_msg "$BLUE" "Securing System..."

    if [[ "$DRY_RUN" = "true" ]]; then
        print_msg "$BLUE" "[DRY RUN] Would configure firewall and SSH hardening"
        return 0
    fi

    # 1. Firewall
    print_msg "$YELLOW" "Configuring firewall..."
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw allow ssh
    echo "y" | sudo ufw enable
    sudo systemctl enable ufw
    print_msg "$GREEN" "✓ Firewall active"

    # 2. SSH Hardening
    print_msg "$YELLOW" "Applying SSH server hardening..."

    # Backup existing configs
    if [[ -f /etc/ssh/sshd_config ]]; then
        sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup.$(date +%s)
    fi

    # Create hardening config in sshd_config.d
    sudo tee /etc/ssh/sshd_config.d/99-hardening.conf > /dev/null <<EOF
# SSH Server Hardening Configuration
# File: /etc/ssh/sshd_config.d/99-hardening.conf

# Disable root login
PermitRootLogin no

# Disable password authentication (use SSH keys only)
PasswordAuthentication no
ChallengeResponseAuthentication no
PermitEmptyPasswords no

# Only allow specific users
AllowUsers $RESTORE_USER
EOF

    # Test configuration
    if sudo sshd -t 2>/dev/null; then
        sudo systemctl restart sshd
        print_msg "$GREEN" "✓ SSH hardening applied"
    else
        log_error "SSH config test failed, rolling back..."
        sudo rm -f /etc/ssh/sshd_config.d/99-hardening.conf
        return 1
    fi

    print_msg "$GREEN" "System security configured!"
}

# --- MAIN ---

full_setup() {
    print_msg "$GREEN" "========================================="
    print_msg "$GREEN" "   FULL SYSTEM RESTORE"
    print_msg "$GREEN" "========================================="
    print_msg "$BLUE" "User: $RESTORE_USER"
    print_msg "$BLUE" "Repo: $BORG_REPO"
    print_msg "$BLUE" "Dry Run: $DRY_RUN"
    print_msg "$GREEN" "========================================="

    restore_shell_config
    restore_kde_config
    restore_misc_configs
    restore_data
    restore_app_configs

    install_base_tools
    install_lean_kde
    install_desktop_apps
    install_music_production
    install_yay_and_aur

    setup_t14s_hardware
    setup_t14s_power
    setup_security

    if [[ "$DRY_RUN" = "true" ]]; then
        print_msg "$BLUE" "[DRY RUN] Would install languages & containers"
    else
        # Languages & Containers
        sudo pacman -S --needed --noconfirm python python-pip go rust docker docker-compose kubectl
        sudo usermod -aG docker $RESTORE_USER
        sudo systemctl enable docker

        sudo ln -sf /usr/bin/vim /usr/bin/vi
    fi

    print_msg "$GREEN" "========================================"
    print_msg "$GREEN" "   SYSTEM RESTORE COMPLETE"
    print_msg "$GREEN" "========================================"
    print_msg "$YELLOW" "Manual Steps Required:"
    print_msg "$YELLOW" "1. Log into Firefox Sync & VS Code Sync."
    print_msg "$YELLOW" "2. Run 'fprintd-enroll' for fingerprint."
    print_msg "$YELLOW" "3. Run './restore-system.sh restore-music' for music setup."
    print_msg "$RED"    "4. Reboot to apply kernel fan control & ZRAM."
    print_msg "$BLUE"   "5. Log file: $LOG_FILE"
}

usage() {
    cat << EOF
Usage: $0 COMMAND [OPTIONS]

Commands:
  full-setup          Complete system restoration (everything except music)
  restore-shell       Restore zsh/p10k shell config
  restore-kde         Restore KDE Plasma & audio configs
  restore-data        Restore user data (bin, Documents, projects)
  restore-app-configs Restore application configs (Calibre, Obsidian, VS Code, etc.)
  restore-music       Restore music production (Bitwig, plugins, wine)
  install-apps        Install desktop applications
  install-music       Install music production stack (yabridge, wine)
  setup-power         Configure T14s power management
  setup-security      Configure firewall + SSH hardening

Environment Variables:
  BORG_REPO           Borg repository path (required: user@host:repo)
  BORG_PASSPHRASE     Borg repository passphrase (required)
  RESTORE_USER        Username to restore for (default: \$USER)
  DRY_RUN             Set to 'true' for dry run mode (default: false)

Examples:
  export BORG_REPO='user@host.repo.borgbase.com:repo'
  export BORG_PASSPHRASE='your-passphrase'
  $0 full-setup                    # Everything except music
  $0 restore-music                 # Add music production after
  DRY_RUN=true $0 full-setup       # Test run without changes
  RESTORE_USER=bob $0 restore-data # Restore for different user
EOF
}

# Check for dry run flag
for arg in "$@"; do
    if [[ "$arg" = "--dry-run" ]]; then
        DRY_RUN=true
        print_msg "$YELLOW" "=== DRY RUN MODE ENABLED ==="
    fi
done

if [[ $# -eq 0 ]]; then
    usage
    exit 1
fi

case "$1" in
    full-setup) full_setup ;;
    restore-shell) restore_shell_config ;;
    restore-kde) restore_kde_config ;;
    restore-data) restore_data ;;
    restore-app-configs) restore_app_configs ;;
    restore-music) restore_music_production ;;
    install-apps) install_desktop_apps ;;
    install-music) install_music_production ;;
    setup-power) setup_t14s_power ;;
    setup-security) setup_security ;;
    *) usage ;;
esac
