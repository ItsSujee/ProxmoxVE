#!/usr/bin/env bash

# Copyright (c) 2024 itssujee
# Author: itssujee
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y curl
$STD apt-get install -y sudo
$STD apt-get install -y mc
msg_ok "Installed Dependencies"

get_latest_release() {
  curl -sL https://api.github.com/repos/$1/releases/latest | grep '"tag_name":' | cut -d'"' -f4
}

DOCKER_LATEST_VERSION=$(get_latest_release "moby/moby")
BLUESKYPDS_LATEST_VERSION="0.4"
PDSADMIN_URL="https://raw.githubusercontent.com/bluesky-social/pds/main/pdsadmin.sh"

msg_info "Installing Docker $DOCKER_LATEST_VERSION"
DOCKER_CONFIG_PATH='/etc/docker/daemon.json'
mkdir -p $(dirname $DOCKER_CONFIG_PATH)
echo -e '{\n  "log-driver": "journald"\n}' >/etc/docker/daemon.json
$STD sh <(curl -sSL https://get.docker.com)
msg_ok "Installed Docker $DOCKER_LATEST_VERSION"

msg_info "Pulling BlueSky PDS $BLUESKYPDS_LATEST_VERSION Image"
$STD docker pull ghcr.io/bluesky-social/pds:latest
msg_ok "Pulled BlueSky PDS $BLUESKYPDS_LATEST_VERSION Image"

msg_info "Installing BlueSky PDS $BLUESKYPDS_LATEST_VERSION"
PDS_PATH='/pds'
mkdir -p $(dirname $DOCKER_CONFIG_PATH)
$STD docker run -d --name pds --network host --restart unless-stopped -v /pds:/pds ghcr.io/bluesky-social/pds:latest
msg_ok "Installed BlueSky PDS $BLUESKYPDS_LATEST_VERSION"

msg_info "Creating PDS Service"
cat <<EOF >/etc/systemd/system/pds.service
[Unit]
Description=Bluesky PDS Service
Documentation=https://github.com/bluesky-social/pds
Requires=docker.service
After=docker.service
[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/root/pds
ExecStart=/usr/bin/docker docker run -d --name pds --network host --restart unless-stopped -v /pds:/pds --env-file /pds/pds.env ghcr.io/bluesky-social/pds:latest
ExecStop=/usr/bin/docker stop pds
Restart=always
[Install]
WantedBy=default.target
EOF
systemctl enable pds
systemctl restart pds
msg_ok "Created PDS Service"

msg_info "Downloading pdsadmin tool"
curl -sfSo /usr/local/bin/pdsadmin "${PDSADMIN_URL}"
$STD chmod +x /usr/local/bin/pdsadmin
msg_ok "Downloaded pdsadmin tool"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
