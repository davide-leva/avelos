#!/bin/bash

set -ouex pipefail

# Wayland portals and screen-sharing picker
dnf -y install xdg-desktop-portal-wlr xdg-desktop-portal-gtk slurp

## DNF5 Speedup
sed -i '/^\[main\]/a max_parallel_downloads=10' /etc/dnf/dnf.conf

## System apps
dnf -y install libvirt virt-manager qemu-kvm flatpak-builder wlr-randr iotop sysstat lxqt-openssh-askpass lxpolkit parallel just seahorse android-tools iperf3 ktls-utils podman-compose

# User apps
dnf -y install nautilus kitty mpv gnome-terminal gnome-system-monitor gnome-calculator loupe 

# OBS and fully-featured ffmpeg with nonfree components from rpm fusion
dnf -y install "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"
# dnf -y install ffmpeg x264-libs obs-studio obs-studio-plugin-x264 libva-utils --allowerasing
dnf -y swap ffmpeg-free ffmpeg --allowerasing
dnf -y install ffmpeg-devel x264-libs obs-studio obs-studio-plugin-x264 libva-utils

# dev tools
dnf -y install alsa-lib-devel rustfmt cargo clang clang-devel docker-cli docker-cli.x86_64 docker-compose.x86_64 firejail firetools libX11-devel libxkbcommon-devel moby-engine vulkan-loader-devel wayland-devel clippy cmake docker-buildx git nasm  patchelf perf

# OpenSnitch application firewall (not in Fedora repos): latest upstream release,
# checked against the SHA-256 digests GitHub publishes for the release assets
command -v jq || dnf -y install jq
curl -fsSL https://api.github.com/repos/evilsocket/opensnitch/releases/latest -o /tmp/opensnitch-release.json
OPENSNITCH_RPMS=()
for pattern in '^opensnitch-[0-9.]+-1\.x86_64\.rpm$' '^opensnitch-ui-[0-9.]+-1\.noarch\.rpm$'; do
  read -r name url digest < <(jq -r --arg re "$pattern" \
    '.assets[] | select(.name | test($re)) | "\(.name) \(.browser_download_url) \(.digest)"' /tmp/opensnitch-release.json)
  [[ "$digest" == sha256:* ]] || { echo "no sha256 digest for OpenSnitch asset $pattern"; exit 1; }
  curl -fLo "/tmp/$name" "$url"
  echo "${digest#sha256:}  /tmp/$name" | sha256sum -c -
  OPENSNITCH_RPMS+=("/tmp/$name")
done
# the daemon's %post runs `systemctl start`, which fails without a running systemd:
# install its deps normally, then the daemon without scriptlets and enable it by hand
dnf -y install libnetfilter_queue libnfnetlink
dnf -y install --setopt=tsflags=noscripts "${OPENSNITCH_RPMS[0]}"
dnf -y install "${OPENSNITCH_RPMS[1]}"
systemctl enable opensnitch.service

# Nautilus open any terminal extension
curl -Lo /etc/yum.repos.d/nautilus-open-any-terminal.repo \
  "https://copr.fedorainfracloud.org/coprs/monkeygold/nautilus-open-any-terminal/repo/fedora-$(rpm -E %fedora)/monkeygold-nautilus-open-any-terminal-fedora-$(rpm -E %fedora).repo"
# dnf install -y nautilus-open-any-terminal
# glib-compile-schemas /usr/share/glib-2.0/schemas
# gsettings set com.github.stunkymonkey.nautilus-open-any-terminal terminal kitty


# Intel/AMD integrated graphics: use the Mesa stack from the non-NVIDIA base.
dnf -y install mesa-dri-drivers mesa-vulkan-drivers

# MangoWM and Noctalia Greeter are packaged by Terra.
# Bazzite includes terra-release but disables the main Terra repository.
if ! rpm -q terra-release >/dev/null 2>&1; then
  dnf -y install --nogpgcheck --repofrompath "terra,https://repos.fyralabs.com/terra\$releasever" terra-release
fi
dnf -y --enable-repo=terra install mangowm noctalia-greeter
dnf -y install noctalia greetd dbus-daemon

curl -fLo /etc/yum.repos.d/peterwu.repo \
  "https://copr.fedorainfracloud.org/coprs/peterwu/rendezvous/repo/fedora-$(rpm -E %fedora)/peterwu-rendezvous-fedora-$(rpm -E %fedora).repo"
dnf -y install bibata-cursor-themes

# System fallback also covers existing users without a Mango configuration.
install -Dm644 /ctx/dot_config/mango/config.conf /etc/mango/config.conf
install -Dm644 /ctx/dot_config/mango/config.conf /etc/skel/.config/mango/config.conf
install -Dm644 /ctx/dot_config/xdg-desktop-portal/mango-portals.conf \
  /etc/xdg/xdg-desktop-portal/mango-portals.conf

# Fail the build if the installed compositor cannot parse our configuration.
mango -c /etc/mango/config.conf -p

# greetd runs the greeter's session wrapper; Mango is selected at login.
install -Dm644 /ctx/greetd/config.toml /etc/greetd/config.toml
test -x /usr/bin/noctalia-greeter-session
test -x /usr/bin/noctalia-greeter-apply-appearance
test -f /usr/share/wayland-sessions/mango.desktop

# /var is persistent state in bootc: initialize it on the installed system.
install -Dm644 /ctx/systemd/avelos-greeter-setup.service \
  /usr/lib/systemd/system/avelos-greeter-setup.service
mkdir -p /etc/systemd/system/greetd.service.d
cat > /etc/systemd/system/greetd.service.d/avelos.conf << 'EOF'
[Unit]
Requires=avelos-greeter-setup.service
After=avelos-greeter-setup.service
EOF
systemctl disable gdm.service
rm -f /etc/systemd/system/display-manager.service
systemctl enable --force greetd.service

# DEV packages
# cargo evtest git input-remapper libevdev-devel libinput-utils python3-devel

# dnf -y install bitwarden-cli 

#### Enable podman

systemctl enable podman.socket

# Remove waybar
dnf -y remove waybar

# this is needed for some glib applications
glib-compile-schemas /usr/share/glib-2.0/schemas/


## CLEAN UP
# Clean up dnf cache to reduce image size
dnf5 -y clean all
rm -rf /run/dnf /run/selinux-policy
rm -rf /var/lib/dnf
