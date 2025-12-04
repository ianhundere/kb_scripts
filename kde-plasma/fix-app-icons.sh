#!/bin/bash
set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

print_msg() { echo -e "${1}${*:2}${NC}"; }

print_msg "$BLUE" "Fixing application icons for KDE Wayland/X11..."

mkdir -p ~/.local/share/applications

# signal desktop file fix (wayland)
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
print_msg "$GREEN" "✓ Signal desktop file created"

# bitwig studio desktop file fix (x11)
# startupwmclass must match java class name
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
    print_msg "$GREEN" "✓ Bitwig Studio Beta desktop file created"
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
    print_msg "$GREEN" "✓ Bitwig Studio desktop file created"
fi

# proton mail bridge desktop file fix (wayland flatpak)
# desktop file name must match window resourceClass: ch.proton.bridge-gui
if flatpak list 2>/dev/null | grep -q "ch.protonmail.protonmail-bridge"; then
    cat > ~/.local/share/applications/ch.proton.bridge-gui.desktop <<'EOF'
[Desktop Entry]
Type=Application
Version=1.1
Name=Proton Mail Bridge
GenericName=Proton Mail Bridge for Linux
Comment=Proton Mail Bridge is a desktop application that runs in the background, encrypting and decrypting messages as they enter and leave your computer.
Icon=ch.protonmail.protonmail-bridge
Exec=/usr/bin/flatpak run --branch=stable --arch=x86_64 --command=protonmail-bridge ch.protonmail.protonmail-bridge
Terminal=false
Categories=Office;Email;
StartupWMClass=ch.proton.bridge-gui
StartupNotify=true
X-Desktop-File-Install-Version=0.28
X-Flatpak=ch.protonmail.protonmail-bridge
EOF
    print_msg "$GREEN" "✓ Proton Mail Bridge desktop file created"
fi

# proton vpn desktop file fix (wayland flatpak)
# desktop file name must match window resourceClass: protonvpn-app
if flatpak list 2>/dev/null | grep -q "com.protonvpn.www"; then
    cat > ~/.local/share/applications/protonvpn-app.desktop <<'EOF'
[Desktop Entry]
Name=Proton VPN
Exec=/usr/bin/flatpak run --branch=stable --arch=x86_64 --command=protonvpn-app --file-forwarding com.protonvpn.www @@u %u @@
Terminal=false
Type=Application
Icon=com.protonvpn.www
StartupWMClass=protonvpn-app
StartupNotify=true
Comment=Proton VPN GUI client
Categories=Network;
X-Desktop-File-Install-Version=0.28
X-Flatpak=com.protonvpn.www
EOF
    print_msg "$GREEN" "✓ Proton VPN desktop file created"
fi

# RCU (reMarkable Connection Utility) fix
if [[ -f ~/.local/bin/rcu ]]; then
    # Ensure icon is in the right place
    mkdir -p ~/.local/share/icons
    if [[ -f ~/.local/share/applications/davisr-rcu.png ]]; then
        cp ~/.local/share/applications/davisr-rcu.png ~/.local/share/icons/davisr-rcu.png
        rm -f ~/.local/share/applications/davisr-rcu.png  # clean up orphaned icon
    fi

    # Desktop file name and StartupWMClass must match resourceClass: me.davisr.rcu
    cat > ~/.local/share/applications/me.davisr.rcu.desktop <<EOF
[Desktop Entry]
Type=Application
Name=RCU
Comment=Manage your reMarkable tablet
Exec=$HOME/.local/bin/rcu
Icon=$HOME/.local/share/icons/davisr-rcu.png
StartupWMClass=me.davisr.rcu
Terminal=false
Categories=Utility;
Version=1.0
EOF

    rm -f ~/.local/share/applications/davisr-rcu.desktop 2>/dev/null

    print_msg "$GREEN" "✓ RCU desktop file created"
fi

update-desktop-database ~/.local/share/applications/ 2>/dev/null || true
print_msg "$GREEN" "Desktop icon fixes applied!"
