#!/bin/bash
#
# Download and run the latest release version.
# https://github.com/w3src/sh-amp
#
# Usage
# git clone https://github.com/w3src/sh-amp.git
# cd sh-amp
# chmod +x ./ubuntu/18.04/virtualhost/wizard.sh
# ./ubuntu/18.04/virtualhost/wizard.sh

# Work even if somebody does "sh thisscript.sh".
set -e

# Set constants in the file.
ENVPATH=""
ABSPATH=""
DIRNAME=""
OS_PATH=""
PKGNAME=""

# Set the arguments of the file.
for arg in "${@}"; do
  case "${arg}" in
  --ENVPATH=*)
    ENVPATH="$(echo "${arg}" | sed -E 's/(--ENVPATH=)//')"
    ;;
  --ABSPATH=*)
    ABSPATH="$(echo "${arg}" | sed -E 's/(--ABSPATH=)//')"
    DIRNAME="$(dirname "${ABSPATH}")"
    OS_PATH="$(dirname "${DIRNAME}")"
    PKGNAME="$(basename "${DIRNAME,,}")"
    ;;
  esac
done

# Include the file.
source "${OS_PATH}/utils.sh"
source "${OS_PATH}/functions.sh"
source "${DIRNAME}/functions.sh"

# Make sure the package is installed.
pkgAudit "apache2"

# Run the command wizard.
COMMANDS=(
  "Create a database?"
  "Are you sure you want to delete the database?"
  "Are you sure you want to delete the virtual host?"
  "quit"
)

echo
IFS=$'\n'
PS3="Please select one of the options. (1-${#COMMANDS[@]}): "
select COMMAND in ${COMMANDS[@]}; do
  case "${COMMAND}" in
  "${COMMANDS[0]}")
    echo
    DB_NAME=""
    while [ -z "${DB_NAME}" ]; do
      DB_NAME="$(msg -yn -p1='Enter the database name: ' -p2='Are you sure you want to save this? (y/n) ')"
      if [ -z "$(mysql -u root -e 'SELECT db FROM mysql.db;' | egrep "^${DB_NAME}$")" ] ||
        [ -z "$(mysql -u root -e 'SELECT User FROM mysql.user;' | egrep "^${DB_NAME}$")" ]; then
        echo "${DB_NAME} does not exists."
        DB_NAME=""
      fi
    done
    DB_NAME="${DB_NAME//[^a-zA-Z0-9_]/}"
    DB_NAME="${DB_NAME:0:16}"
    DB_USER="${DB_NAME}"
    DB_PASSWORD="$(openssl rand -base64 12)"
    DB_PASSWORD="${DB_PASSWORD:0:16}"
    create_database "${DB_NAME}" "${DB_USER}" "${DB_PASSWORD}"
    ;;
  "${COMMANDS[1]}")
    echo
    DB_NAME=""
    while [ -z "${DB_NAME}" ]; do
      DB_NAME="$(msg -yn -p1='Enter the database name: ' -p2='Are you sure you want to save this? (y/n) ')"
      if [ -z "$(mysql -u root -e 'SELECT db FROM mysql.db;' | egrep "^${DB_NAME}$")" ] ||
        [ -z "$(mysql -u root -e 'SELECT User FROM mysql.user;' | egrep "^${DB_NAME}$")" ]; then
        echo "${DB_NAME} does not exists."
        DB_NAME=""
      fi
    done
    DB_USER="${DB_NAME}"
    delete_database "${DB_NAME}" "${DB_USER}"
    ;;
  "${COMMANDS[3]}")
    exit 0
    ;;
  esac
done
