#!/usr/bin/env bash
# Author: rodrigo.loza@mojix.com
# Description: Setup hub following the hub installation feature.

set -o errexit
set -o pipefail
set -o nounset

#############################################
###########  SUPPORT FUNCTIONS ##############
#############################################
help() {
  echo "Usages:                               " >&2
  echo "  1. Create user                      "
  echo "     bash install.sh -u=admin"
  echo "                                      "
  echo "  2. Create hub                       "
  echo "     bash install.sh -t=RED -e=STAGING -h=CHE041-HUB01        "
  echo "                                      "
  exit 1
}

timestamp() {
  date "+%H:%M:%S.%3N"
}

info() {
  local msg=$1
  echo -e "\e[1;32m[info] $(timestamp) ${msg}\e[0m"
}

warn() {
  local msg=$1
  echo -e "\e[33m[warn] $(timestamp) ${msg}\e[0m"
}

fail() {
  local msg=$1
  if [[ -z $2 ]]; then
    local will_fail=true
  else
    local will_fail=$2
  fi
  echo -e "\e[1;31m[err] $(timestamp) ERROR: ${msg}\e[0m"
  if [[ ${will_fail} == true ]]; then
    exit 1
  fi
}

slack_notification() {
  content=$1
  curl -X POST \
    -H "Content-Type: application/json" \
    https://hooks.slack.com/services/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 \
    --data "{ \"text\": \"${content}\", \"channel\": \"hub_notifications\" }"
}

install_packages() {
  info "..."
  info "Installing linux packages."
  apt-get install -y jq dnsutils nmap zip
  info "..."
}

#############################################
############  LOGIC FUNCTIONS ###############
#############################################
healthchecks() {
  # Check partners.vizix.io is reachable.
  if [[ $1 == "internet" ]]; then
    info "..."
    info "Running internet healthcheck."
    nslookup partners.vizix.io >/dev/null 2>&1
    if [[ $? -ne 0 ]]; then
      fail "The site partners.vizix.io is not reachable. Contact IT to check your internet connection or DNS servers." true
    else
      info "Internet healthcheck successful."
      info "..."
    fi
  # Test vpn is connected.
  elif [[ $1 == "vpn" ]]; then
    vpn_gateway=$2
    if [[ $(nmap -p443 "${vpn_gateway}" | grep "open" | wc -l) -ge 1 ]]; then
      info "..."
      info "VPN Connected."
      info "..."
    else
      fail "VPN Failed. Check installation. If this problem persists contact support." true
    fi
  else
    fail "Healthcheck not supported." true
  fi
}

is_user_root() {
  if [ "$(id -nu)" != "root" ]; then
    echo "$(tput setaf 1)This script must be executed with root privileges.$(tput setaf 0)"
    exit 1
  fi
}

deserialize_json() {
  # keys: tenant, environment, deviceId, usesVpn, ip, url, password, vpnNetworkSegment, message, statusCode
  json=$1
  key=$2
  value=$(echo "${json}" | jq -r ".${key}")
  echo "${value}"
}

install_hub() {
  # Docker login.
  docker login -umojixpull -pAL2DR8en7PvLDZXFQipcLQQY >/dev/null 2>&1
  if [[ $? -ne 0 ]]; then
    fail "Could not login to dockerhub. Contact IT and check the internet connection." true
  fi
  # Variables.
  payload=$1
  vpn=$2
  user="HUBroot"
  password="h@b@dm1n"
  authorization_header=$(echo -n "${user}:${password}" | base64)
  #url="http://localhost:80/hub-api/rest/search/hub"
  url="https://partners.vizix.io/hub-api/rest/search/hub"

  # Get hub object from the cloud.
  content=$(curl -sX POST -H "Authorization: Basic ${authorization_header}" -H "Content-Type: application/json" "${url}" --data "${payload}")

  # Chech if hub has been found.
  message=$(deserialize_json "${content}" "message")
  status_code=$(deserialize_json "${content}" "statusCode")
  if [[ "${status_code}" -lt 200 || "${status_code}" -gt 399 ]]; then
    fail "${message}" true
  else
    tenant=$(deserialize_json "${content}" "tenant")
    environment=$(deserialize_json "${content}" "environment")
    device_id=$(deserialize_json "${content}" "deviceId")
    info "..."
    info "Hub ${device_id} found for tenant ${tenant} in environment ${environment}."
    info "..."
    #warn "${status_code}"
    #warn "${content}"
  fi;

  # Install vpn?
  uses_vpn=$(deserialize_json "${content}" "usesVpn")
  if [[ "${uses_vpn}" == "true" && "${vpn}" == "true" ]]; then
    # Deserialize json and download vpn file.
    info "..."
    info "Setting up VPN."
    url=$(deserialize_json "${content}" "url")
    filename=$(echo "${url}" | awk -F'static-files/' '{ print $2 }' | awk -F'.zip' '{ print $1 }')
    wget --header "Authorization: Basic ${authorization_header}" "${url}" -O /tmp/tmp.zip >/dev/null 2>&1

    # Deserialize password and unzip content.
    info "Setting up VPN."
    filepath="/etc/openvpn/client/${filename}.conf"
    if [[ -f "${filepath}" ]]; then
      systemctl stop openvpn-client@"${filename}"
      systemctl disable openvpn-client@"${filename}"
      rm "${filepath}"
    fi;
    password=$(deserialize_json "${content}" "password")
    unzip -P "${password}" /tmp/tmp.zip -d /etc/openvpn/client/ >/dev/null 2>&1
    info "..."

    # Start vpn.
    info "..."
    info "Starting vpn."
    systemctl start openvpn-client@"${filename}"
    systemctl enable openvpn-client@"${filename}"
  fi;
  # Check vpn if the hub uses vpn.
  if [[ "${uses_vpn}" == "true" ]]; then
    info "Checking vpn status."
    vpn_gateway=$(deserialize_json "${content}" "vpnNetworkSegment")
    healthchecks "vpn" "${vpn_gateway}"
    info "..."
  fi;

  # Setup hub hostname.
  info "..."
  info "Setting up hostname."
  device_id=$(deserialize_json "${content}" "deviceId")
  hostnamectl set-hostname "${device_id}"
  sed -i -e "/127.0.0.1/c\127.0.0.1 ${device_id}" /etc/hosts 2>/dev/null
  #echo "${device_id}" >> /etc/hosts
  info "Hostname set to ${device_id}"
  info "..."

  # Download docker container with ansible installer.
  # Pull docker image.
  #docker pull gcr.io/mojix-registry/ytem-hub-deployment-tool:v2.0.1
  docker pull mojix/ytem-hub-deployment-tool:PR-383
  # Check if registry is reachable.
  if [[ $? -ne 0 ]]; then
    fail "Mojix registry not reachable. Check your internet connection." true
  fi

  # keys: tenant, environment, premiseCode, deviceId, failoverHub, usesVpn, ip, url, password, vpnNetworkSegment, message, statusCode
  # Run docker container with ansible installer.
  failover_hub=$(deserialize_json "${content}" "failoverHub")
  tenant=$(deserialize_json "${content}" "tenant")
  environment=$(deserialize_json "${content}" "environment")
  premise_code=$(deserialize_json "${content}" "premiseCode")
  device_id=$(deserialize_json "${content}" "deviceId")
  ip=$(deserialize_json "${content}" "ip")
  docker run -e MODE=INSTALL \
    -e TENANT="${tenant}" \
    -e ENVIRONMENT="${environment}" \
    -e PREMISE_CODE="${premise_code}" \
    -e DEVICE_ID="${device_id}" \
    -e IP_ADDRESS="${ip}" \
    -e FAILOVER_HUB="${failover_hub}" \
    -e USES_VPN="${uses_vpn}" \
    mojix/ytem-hub-deployment-tool:PR-383

  # Send notification to slack.
  slack_notification "${content}"
}

disable_usb_ports() {
  info "..."
  info "Disabling USB ports."
  filepath="/etc/modprobe.d/blacklist.conf"
  echo "blacklist uas" >>"${filepath}"
  echo "blacklist usb_storage" >>"${filepath}"
  info "USB ports disabled."
  info "..."
}

create_new_user() {
  # Create new user.
  username=$1
  read -p "Enter password:  " userpass

  if [[ -z ${username} || -z ${userpass} ]]; then
    fail "Username: ${username} or password: ${userpass} is empty." true
  fi

  if id -u "${username}" >/dev/null 2>&1; then
    warn "User ${username} already exists. Skipping."
  else
    info "Creating user: ${username}"
    adduser ${username} --home /home/${username} --shell /bin/bash --disabled-password --gecos ""
  fi

  usermod -aG sudo,docker ${username}
  echo "${username}:${userpass}" | chpasswd
}

###############################
###########  MAIN #############
###############################
is_user_root
install_packages

while getopts t:e:h:v:u:p: option; do
  case "${option}" in
  t) TENANT=${OPTARG} ;;
  e) ENVIRONMENT=${OPTARG} ;;
  h) HUB=${OPTARG} ;;
  v) VPN=${OPTARG} ;;
  u) USER=${OPTARG}
     create_new_user "${USER}"
     exit 0
     ;;
  p) help ;;
  esac
done

if [[ -z "${TENANT}" ]]; then
  help
  fail "Parameter -t is empty. Make sure a value has been assigned."
elif [[ -z "${ENVIRONMENT}" ]]; then
  help
  fail "Parameter -e is empty. Make sure a value has been assigned."
elif [[ -z "${HUB}" ]]; then
  help
  fail "Parameter -h is empty. Make sure a value has been assigned."
fi;
if [[ -z "${VPN}" ]]; then
  VPN=false
else
  if [[ "${VPN}" != "true" ]]; then
    VPN=false
  fi;
fi;
info "Searching for hub: ${HUB} in tenant: ${TENANT} and environment: ${ENVIRONMENT}"
payload="{ \"tenant\": \"${TENANT}\", \"environment\": \"${ENVIRONMENT}\", \"deviceId\": \"${HUB}\" }"

# Execute hub installation.
healthchecks "internet"
install_hub "${payload}" "${VPN}"
disable_usb_ports
info "------------------- HUB INSTALLATION SUCCESSFUL ✅ ----------------------"
