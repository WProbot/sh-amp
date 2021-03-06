#!/bin/bash
#
# Download and run the latest release version.
# https://github.com/w3src/sh-amp
#
# Usage
# git clone https://github.com/w3src/sh-amp.git
# cd sh-amp
# chmod +x ./ubuntu/18.04/vsftpd/install.sh
# ./ubuntu/18.04/vsftpd/install.sh

# Work even if somebody does "sh thisscript.sh".
set -e

# Set constants.
OSPATH="$(dirname "$(dirname $0)")"
PKGPATH="$(dirname $0)"
PKGNAME="$(basename "$(dirname $0)")"
FILENAME="$(basename $0)"

# Set directory path.
ABSROOT="$(cd "$(dirname "")" && pwd)"
ABSENV="${ABSROOT}/env"
ABSOS="${ABSROOT}/${OSPATH}"
ABSPKG="${ABSOS}/${PKGNAME}"
ABSPATH="${ABSPKG}/${FILENAME}"

# Include the file.
source "${ABSOS}/utils.sh"
source "${ABSOS}/functions.sh"
source "${ABSPKG}/functions.sh"

echo
echo "Start installing ${PKGNAME}."

# Make sure the package is installed.
if [ ! -z "$(is${PKGNAME^})" ]; then
  CONFIRM_MESSAGE="$(msg -yn "The ${PKGNAME} package is already installed. Would you like to reinstall? ")"
  if [ CONFIRM_MESSAGE == "No" ]; then
    exit 0
  fi
fi

apt -y install vsftpd

# Start the package and set it to start on boot.
pkgOnBoot "vsftpd"

# Create backup and configuration files.
addPkgCnf "/etc/vsftpd.conf"
addPkgCnf "/etc/ftpusers"
addPkgCnf "/etc/vsftpd.user_list"
addPkgCnf "/etc/vsftpd.chroot_list"

# Add a variable to the env file.
setPkgCnf -rs="\[VSFTPD\]" -fs="=" -o="<<HERE
VSFTPD_VERSION = $(getVsftpdVer)
<<HERE"

echo
echo "${PKGNAME^} is completely installed."
