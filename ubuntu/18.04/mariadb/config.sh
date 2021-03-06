#!/bin/bash
#
# Download and run the latest release version.
# https://github.com/w3src/sh-amp
#
# Usage
# git clone https://github.com/w3src/sh-amp.git
# cd sh-amp
# chmod +x ./ubuntu/18.04/mariadb/config.sh
# ./ubuntu/18.04/mariadb/config.sh

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

# Make sure the package is installed.
pkgAudit "${PKGNAME}"

echo
echo "Start setting up ${PKGNAME} configuration."

# Set the arguments.
for arg in "${@}"; do
  case $arg in
  --my)
    IFS=$'\n'
    for i in $(find "${ABSPKG}/etc" -type f -name "[^_]*"); do
      cp "$i" "$(echo "$i" | sed "s/${ABSPKG//\//\\/}//")"
    done
    echo "${PKGNAME^} configuration is complete."
    exit 0
    ;;
  esac
done

# Edit the string using here document.
cat >/etc/my.cnf <<MYCNFSCRIPT
$(cat "${ABSPKG}/tmpl/my.cnf")
MYCNFSCRIPT

# Reloading the package.
systemctl reload mariadb
systemctl reload apache2

echo
echo "${PKGNAME^} configuration is complete."
