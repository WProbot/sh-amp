#!/bin/bash
#
# Download and run the latest release version.
# https://github.com/w3src/sh-amp
#
# Usage
# git clone https://github.com/w3src/sh-amp.git
# cd sh-amp
# chmod +x ./ubuntu/18.04/php/reset.sh
# ./ubuntu/18.04/php/reset.sh

# Work even if somebody does "sh thisscript.sh".
set -e

# Set constants.
OSPATH="$(dirname "$(dirname $0)")"
PKGPATH="$(dirname $0)"
PKGNAME="$(basename "$(dirname $0)")"
FILENAME="$(basename $0)"

# Set directory path.
ABSROOT="${1#*=}"
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
echo "Reset the ${PKGNAME} configuration."

# Import variables from the env file.
PHP_VERSION="$(getPkgCnf -rs="\[PHP\]" -fs="=" -s="PHP_VERSION")"

# Reset the file.
cp -v "/etc/apache2/mods-available/dir.conf.bak" "/etc/apache2/mods-available/dir.conf"
cp -v "/etc/apache2/mods-available/php${PHP_VERSION}.conf.bak" "/etc/apache2/mods-available/php${PHP_VERSION}.conf"
cp -v "/etc/php/${PHP_VERSION}/apache2/php.ini.bak" "/etc/php/${PHP_VERSION}/apache2/php.ini"

# Reloading the service.
systemctl reload apache2

echo
echo "The ${PKGNAME} configuration has been reset."