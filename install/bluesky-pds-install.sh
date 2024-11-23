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
$STD apt-get install -y sqlite3
$STD apt-get install -y openssl
msg_ok "Installed Dependencies"

get_latest_release() {
  curl -sL https://api.github.com/repos/$1/releases/latest | grep '"tag_name":' | cut -d'"' -f4
}

DOCKER_LATEST_VERSION=$(get_latest_release "moby/moby")
BLUESKYPDS_LATEST_VERSION="0.4"
PDS_DID_PLC_URL="https://plc.directory"
PDS_BSKY_APP_VIEW_URL="https://api.bsky.app"
PDS_BSKY_APP_VIEW_DID="did:web:api.bsky.app"
PDS_REPORT_SERVICE_URL="https://mod.bsky.app"
PDS_REPORT_SERVICE_DID="did:plc:ar7c4by46qjdydhdevvrndac"
PDS_CRAWLERS="https://bsky.network"
PDSADMIN_URL="https://raw.githubusercontent.com/bluesky-social/pds/main/pdsadmin.sh"
GENERATE_SECURE_SECRET_CMD="openssl rand --hex 16"
GENERATE_K256_PRIVATE_KEY_CMD="openssl ecparam --name secp256k1 --genkey --noout --outform DER | tail --bytes=+8 | head --bytes=32 | xxd --plain --cols 32"
PDS_ADMIN_PASSWORD=$(eval "${GENERATE_SECURE_SECRET_CMD}")


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

$STD mkdir "/root/pds"

cat <<PDS_CONFIG >"/root/pds/pds.env"
PDS_HOSTNAME=${PDS_HOSTNAME}
PDS_JWT_SECRET=$(eval "${GENERATE_SECURE_SECRET_CMD}")
PDS_ADMIN_PASSWORD=${PDS_ADMIN_PASSWORD}
PDS_PLC_ROTATION_KEY_K256_PRIVATE_KEY_HEX=$(eval "${GENERATE_K256_PRIVATE_KEY_CMD}")
PDS_DATA_DIRECTORY=/root/pds/blocks
PDS_BLOBSTORE_DISK_LOCATION=/root/pds/blocks
PDS_BLOB_UPLOAD_LIMIT=52428800
PDS_DID_PLC_URL=${PDS_DID_PLC_URL}
PDS_BSKY_APP_VIEW_URL=${PDS_BSKY_APP_VIEW_URL}
PDS_BSKY_APP_VIEW_DID=${PDS_BSKY_APP_VIEW_DID}
PDS_REPORT_SERVICE_URL=${PDS_REPORT_SERVICE_URL}
PDS_REPORT_SERVICE_DID=${PDS_REPORT_SERVICE_DID}
PDS_CRAWLERS=${PDS_CRAWLERS}
LOG_ENABLED=true
PDS_CONFIG

$STD docker run -d --name pds --network host --restart unless-stopped -v /pds:/pds -env_file /pds/pds.env ghcr.io/bluesky-social/pds:latest

# cat <<EOF >/etc/systemd/system/pds.service
# [Unit]
# Description=Bluesky PDS Service
# After=docker.service

# [Service]
# Type=oneshot
# RemainAfterExit=yes
# WorkingDirectory=/root/pds
# ExecStart=/usr/bin/docker run -d --name pds --network host --restart unless-stopped -v /pds:/pds -env_file /pds/pds.env ghcr.io/bluesky-social/pds:latest
# ExecStop=/usr/bin/docker stop pds
# Restart=always

# [Install]
# WantedBy=multi-user.target
# EOF
# systemctl daemon-reload
# systemctl enable -q --now pds
msg_ok "Installed BlueSky PDS $BLUESKYPDS_LATEST_VERSION"

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
