#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: benjaminbear
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://jdownloader.org/ | https://protonvpn.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  curl \
  sudo \
  mc \
  wget \
  gnupg \
  apt-transport-https \
  openjdk-17-jre-headless \
  ffmpeg \
  libfuse2 \
  python3-pip \
  openvpn \
  network-manager \
  network-manager-openvpn \
  resolvconf
msg_ok "Installed Dependencies"

msg_info "Setting up TUN Device"
mkdir -p /dev/net
if [[ ! -c /dev/net/tun ]]; then
  mknod /dev/net/tun c 10 200 2>/dev/null || true
fi
chmod 600 /dev/net/tun 2>/dev/null || true
msg_ok "Set up TUN Device"

msg_info "Installing Proton VPN CLI"
# Download Proton VPN repository package
wget -q https://repo.protonvpn.com/debian/dists/stable/main/binary-all/protonvpn-stable-release_1.0.8_all.deb -O /tmp/protonvpn-release.deb

# Install the repository package
dpkg -i /tmp/protonvpn-release.deb &>/dev/null || true

# Fix sources.list for Debian 13 (Trixie) - use bookworm repo
for f in /etc/apt/sources.list.d/protonvpn*.list; do
  if [[ -f "$f" ]]; then
    sed -i 's/trixie/bookworm/g' "$f"
  fi
done

# Update package lists
apt-get update &>/dev/null

# Install protonvpn-cli
apt-get install -y protonvpn-cli &>/dev/null || {
  msg_info "Official package failed, trying pip installation..."
  pip3 install protonvpn-cli --break-system-packages &>/dev/null || pip3 install protonvpn-cli &>/dev/null
}

rm -f /tmp/protonvpn-release.deb
msg_ok "Installed Proton VPN CLI"

msg_info "Installing JDownloader2"
mkdir -p /opt/JDownloader
$STD wget -q http://installer.jdownloader.org/JDownloader.jar -O /opt/JDownloader/JDownloader.jar

# Create JDownloader configuration directory
mkdir -p /opt/JDownloader/cfg

# Pre-configure JDownloader for headless operation
cat <<'EOF' >/opt/JDownloader/cfg/org.jdownloader.api.myjdownloader.MyJDownloaderSettings.json
{
  "autoconnectaliases" : true,
  "debugenabled" : false
}
EOF
msg_ok "Installed JDownloader2"

msg_info "Creating Download Directory"
mkdir -p /downloads
chmod 755 /downloads
msg_ok "Created Download Directory at /downloads"

msg_info "Creating JDownloader Service"
cat <<'EOF' >/etc/systemd/system/jdownloader.service
[Unit]
Description=JDownloader2 Download Manager
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/JDownloader
ExecStart=/usr/bin/java -Djava.awt.headless=true -jar /opt/JDownloader/JDownloader.jar
Restart=on-failure
RestartSec=10
TimeoutStopSec=20

# Security hardening
NoNewPrivileges=false
ProtectSystem=false
ProtectHome=false

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable -q jdownloader
systemctl start jdownloader
msg_ok "Created and Started JDownloader Service"

msg_info "Creating Proton VPN Helper Scripts"
# Detect which command is available (protonvpn-cli or protonvpn)
if command -v protonvpn-cli &>/dev/null; then
  VPN_CMD="protonvpn-cli"
  CONNECT_ARGS="connect --fastest"
  DISCONNECT_ARGS="disconnect"
  STATUS_ARGS="status"
elif command -v protonvpn &>/dev/null; then
  VPN_CMD="protonvpn"
  CONNECT_ARGS="c -f"
  DISCONNECT_ARGS="d"
  STATUS_ARGS="s"
else
  VPN_CMD="protonvpn-cli"
  CONNECT_ARGS="connect --fastest"
  DISCONNECT_ARGS="disconnect"
  STATUS_ARGS="status"
fi

# Create a helper script for connecting to VPN
cat <<EOF >/usr/local/bin/vpn-connect
#!/bin/bash
# Quick connect to fastest Proton VPN server
$VPN_CMD $CONNECT_ARGS
EOF
chmod +x /usr/local/bin/vpn-connect

# Create a helper script for disconnecting
cat <<EOF >/usr/local/bin/vpn-disconnect
#!/bin/bash
# Disconnect from Proton VPN
$VPN_CMD $DISCONNECT_ARGS
EOF
chmod +x /usr/local/bin/vpn-disconnect

# Create a helper script for status
cat <<EOF >/usr/local/bin/vpn-status
#!/bin/bash
# Show Proton VPN connection status
$VPN_CMD $STATUS_ARGS
EOF
chmod +x /usr/local/bin/vpn-status
msg_ok "Created VPN Helper Scripts"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"

