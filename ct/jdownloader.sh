#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: benjaminbear
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://jdownloader.org/ | https://protonvpn.com/

# Override the install script URL to use our own repository
REPO_URL="https://raw.githubusercontent.com/benjaminbear/jdownloader-lxc/main"

source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)

# App Default Values
APP="JDownloader"
var_tags="downloader;vpn;protonvpn"
var_cpu="2"
var_ram="2048"
var_disk="8"
var_os="debian"
var_version="13"
var_unprivileged="1"

# App Output & Base Settings
header_info "$APP"
base_settings

# Core
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -f /opt/JDownloader/JDownloader.jar ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  msg_info "Updating JDownloader2"
  cd /opt/JDownloader
  java -jar JDownloader.jar -update
  msg_ok "Updated JDownloader2"
  
  msg_info "Updating Proton VPN CLI"
  apt-get update &>/dev/null
  apt-get install -y protonvpn-cli &>/dev/null
  msg_ok "Updated Proton VPN CLI"
  exit
}

# Override the install function to use our repository
function install_script() {
  pct exec "$CTID" -- bash -c "$(curl -fsSL ${REPO_URL}/install/jdownloader-install.sh)"
}

start
build_container

# Run our custom install script
msg_info "Running installation script from ${REPO_URL}"
pct exec "$CTID" -- bash -c "$(curl -fsSL ${REPO_URL}/install/jdownloader-install.sh)" || {
  msg_error "Failed to run install script"
  exit 1
}

# Add TUN device configuration for VPN support
msg_info "Configuring TUN device access for VPN"
LXC_CONFIG="/etc/pve/lxc/${CTID}.conf"
if ! grep -q "lxc.cgroup2.devices.allow: c 10:200 rwm" "$LXC_CONFIG"; then
  echo "lxc.cgroup2.devices.allow: c 10:200 rwm" >> "$LXC_CONFIG"
fi
if ! grep -q "lxc.mount.entry: /dev/net/tun" "$LXC_CONFIG"; then
  echo "lxc.mount.entry: /dev/net/tun dev/net/tun none bind,create=file" >> "$LXC_CONFIG"
fi
msg_ok "Configured TUN device access"

# Restart container to apply TUN device config
msg_info "Restarting container to apply TUN configuration"
pct reboot "$CTID" &>/dev/null
sleep 5
msg_ok "Container restarted"

description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} JDownloader2 is running in headless mode.${CL}"
echo -e "${INFO}${YW} Configure MyJDownloader at: https://my.jdownloader.org${CL}"
echo -e "${INFO}${YW} Downloads directory: /downloads${CL}"
echo -e ""
echo -e "${INFO}${YW} To configure Proton VPN, enter the container and run:${CL}"
echo -e "${TAB}${BGN}protonvpn-cli login <username>${CL}"
echo -e "${TAB}${BGN}protonvpn-cli connect --fastest${CL}"
echo -e ""
echo -e "${INFO}${YW} To enable kill switch:${CL}"
echo -e "${TAB}${BGN}protonvpn-cli ks --on${CL}"

