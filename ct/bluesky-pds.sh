#!/usr/bin/env bash

source <(curl -s https://raw.githubusercontent.com/ItsSujee/ProxmoxVE/refs/heads/bluesky-pds/misc/build.func)
# Copyright (c) 2024 itssujee
# Author: itssujee
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
clear
cat <<"EOF"
    ____  __          _____ __            ____  ____  _____
   / __ )/ /_  _____ / ___// /____  __   / __ \/ __ \/ ___/
  / __  / / / / / _ \\__ \/ //_/ / / /  / /_/ / / / /\__ \ 
 / /_/ / / /_/ /  __/__/ / ,< / /_/ /  / ____/ /_/ /___/ / 
/_____/_/\__,_/\___/____/_/|_|\__, /  /_/   /_____//____/  
                             /____/                        
EOF
}
header_info
echo -e "Loading..."
APP="BlueSky-PDS"
var_disk="20"
var_cpu="2"
var_ram="2048"
var_os="ubuntu"
var_version="22.04"
variables
color
catch_errors

function default_settings() {
  CT_TYPE="1"
  PW=""
  CT_ID=$NEXTID
  HN=$NSAPP
  DISK_SIZE="$var_disk"
  CORE_COUNT="$var_cpu"
  RAM_SIZE="$var_ram"
  BRG="vmbr0"
  NET="dhcp"
  GATE=""
  APT_CACHER=""
  APT_CACHER_IP=""
  DISABLEIP6="no"
  MTU=""
  SD=""
  NS=""
  MAC=""
  VLAN=""
  SSH="no"
  VERB="no"
  echo_default
}

start
build_container
description

cat <<INSTALLER_MESSAGE
========================================================================
PDS installation successful!
------------------------------------------------------------------------

Check service status      : sudo systemctl status pds
Watch service logs        : sudo docker logs -f pds
Backup service data       : /root/pds
PDS Admin command         : pdsadmin

To see pdsadmin commands, run "pdsadmin help"

========================================================================
INSTALLER_MESSAGE