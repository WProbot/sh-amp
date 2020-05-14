#!/bin/bash
#
# Download and run the latest release version.
# https://github.com/w3src/sh-amp
#
# Usage
# git clone https://github.com/w3src/sh-amp.git
# cd sh-amp
# chmod +x ./ubuntu/18.04/ufw/install.sh
# ./ubuntu/18.04/ufw/install.sh

# Work even if somebody does "sh thisscript.sh".
set -e

# Set constants in the file.
ENVPATH=""
ABSPATH=""
OS_PATH=""

# Set the arguments of the file.
for arg in "${@}"; do
  case "${arg}" in
  --ENVPATH=*)
    ENVPATH="$(echo "${arg}" | sed -E 's/(--ENVPATH=)//')"
    ;;
  --ABSPATH=*)
    ABSPATH="$(echo "${arg}" | sed -E 's/(--ABSPATH=)//')"
    OS_PATH="$(dirname "$(dirname "${ABSPATH}")")"
    ;;
  esac
done

# Include the file.
source "${OS_PATH}/utils.sh"
source "${OS_PATH}/functions.sh"
source "functions.sh"

echo
echo "Start installing ufw."

apt -y install ufw

# Add a variable to the env file.
addPkgCnf -rs="\[UFW\]" -fs="=" -o="<<HERE
UFW_VERSION = $(getUfwVer)
<<HERE"

# Reload the service.
if [ ! -z "$(isApache2)" ]; then
  systemctl reload apache2
fi

echo
echo "Ufw is completely installed."