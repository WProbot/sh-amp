#!/bin/bash
#
# Download and run the latest release version.
# https://github.com/w3src/sh-amp
#
# Usage
# git clone https://github.com/w3src/sh-amp.git
# cd sh-amp
# chmod +x ./ubuntu/18.04/apache2/config.sh
# ./ubuntu/18.04/apache2/config.sh

# Work even if somebody does "sh thisscript.sh".
set -e

# Set global constants.
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
pkgAudit "${PKGNAME}"

echo
echo "Start setting up ${PKGNAME} configuration."

f_charset="/etc/apache2/conf-available/charset.conf"

if [ -f ".${f_charset}" ]; then
  cp -v ".${f_charset}" "${f_charset}"
else
  sed -i -E \
    -e "/^[#\t ]{0,}AddDefaultCharset\s{1,}/{ s/^[#\t ]{1,}//; }" \
    "${f_charset}"
fi

# This currently breaks the configurations that come with some web application Debian packages.
# Hide server version and virtual host name on the client.
# prevent MSIE from interpreting files as some else.
# This depends against clickjacking attacks.
f_security="/etc/apache2/conf-available/security.conf"

if [ -f ".${f_security}" ]; then
  cp -v ".${f_security}" "${f_security}"
else
  if [ -z "$(cat "${f_security}" | egrep '^[#\t ]{0,}ServerTokens\s{1,}Prod')" ]; then
    sed -i -E \
      -e "/^[#\t ]{0,}ServerTokens\s{1,}Full/a\ServerTokens Prod" \
      "${f_security}"
  fi
  sed -i -E \
    -e "/^[#\t ]{0,}<Directory\s{1,}\/>/,/^[#\t ]{0,}<\/Directory>/{ s/^[#]{1,}//; }" \
    -e "/^[#\t ]{0,}ServerTokens\s{1,}OS/{ s/^/#/; s/^[#\t ]{1,}/#/; }" \
    -e "/^[#\t ]{0,}ServerTokens\s{1,}Full/{ s/^/#/; s/^[#\t ]{1,}/#/; }" \
    -e "/^[#\t ]{0,}ServerTokens\s{1,}Prod/{ s/^[#\t ]{1,}//; }" \
    -e "/^[#\t ]{0,}ServerSignature\s{1,}On/{ s/^/#/; s/^[#\t ]{1,}/#/; }" \
    -e "/^[#\t ]{0,}ServerSignature\s{1,}Off/{ s/^[#\t ]{1,}//; }" \
    -e "/^[#\t ]{0,}Header\s{1,}set\s{1,}X-Content-Type-Options\s{0,}\:/{ s/^[#\t ]{1,}//; }" \
    -e "/^[#\t ]{0,}Header\s{1,}set\s{1,}X-Frame-Options\s{0,}\:/{ s/^[#\t ]{1,}//; }" \
    "${f_security}"
fi

f_apache2="/etc/apache2/apache2.conf"

if [ -f ".${f_apache2}" ]; then
  cp -v ".${f_apache2}" "${f_apache2}"
else
  if [ -z "$(cat "${f_apache2}" | egrep 'This is a configuration dynamically generated by Amp Stack.')" ]; then
    sed -E -i '/# vim: syntax=apache(.*)noet/d' "${f_apache2}"
    cat >>"${f_apache2}" <<APACHE2SCRIPT
$(cat "${DIRNAME}/tmpl/apache2.conf")
APACHE2SCRIPT
  fi
fi

# prefork MPM
# StartServers: number of server processes to start
# MinSpareServers: minimum number of server processes which are kept spare
# MaxSpareServers: maximum number of server processes which are kept spare
# MaxRequestWorkers: maximum number of server processes allowed to start
# MaxConnectionsPerChild: maximum number of requests a server process serves
STARTSERVERS=10
MAXREQUESTWORKERS=300
MAXCONNECTIONSPERCHILD=0
MINSPARESERVERS=${STARTSERVERS}
MAXSPARESERVERS=$((${MINSPARESERVERS} * 2))
SERVERLIMIT=${MAXREQUESTWORKERS}

echo
echo "Would you like to install mpm_prefork with the following settings?"
echo "STARTSERVERS: ${STARTSERVERS}"
echo "MINSPARESERVERS: ${MINSPARESERVERS}"
echo "MAXSPARESERVERS: ${MAXSPARESERVERS}"
echo "MAXREQUESTWORKERS: ${MAXREQUESTWORKERS}"
echo "SERVERLIMIT: ${SERVERLIMIT}"
echo "MAXCONNECTIONSPERCHILD: ${MAXCONNECTIONSPERCHILD}"

CHANGE_MESSAGE="$(msg -yn "Do you want to change it? (y/n) ")"
if [ "${CHANGE_MESSAGE}" == "Yes" ]; then
  NEW_CONFIG=""
  while [ -z "${NEW_CONFIG}" ]; do
    read -p "STARTSERVERS: " NEW_STARTSERVERS
    read -p "MAXREQUESTWORKERS: " NEW_MAXREQUESTWORKERS
    read -p "MAXCONNECTIONSPERCHILD: " NEW_MAXCONNECTIONSPERCHILD
    read -p "MINSPARESERVERS: " NEW_MINSPARESERVERS
    read -p "MAXSPARESERVERS: " NEW_MAXSPARESERVERS
    read -p "SERVERLIMIT: " NEW_SERVERLIMIT
    SAVE_MESSAGE="$(msg -ync "Do you want to save it? (y/n/c) ")"
    case "${SAVE_MESSAGE}" in
    "Yes")
      STARTSERVERS="${NEW_STARTSERVERS}"
      MAXREQUESTWORKERS="${NEW_MAXREQUESTWORKERS}"
      MAXCONNECTIONSPERCHILD="${NEW_MAXCONNECTIONSPERCHILD}"
      MINSPARESERVERS="${NEW_MINSPARESERVERS}"
      MAXSPARESERVERS="${NEW_MAXSPARESERVERS}"
      SERVERLIMIT="${NEW_SERVERLIMIT}"
      NEW_CONFIG="Yes"
      break
      ;;
    "No")
      NEW_CONFIG=""
      ;;
    "Cancel")
      NEW_CONFIG=""
      break
      ;;
    esac
  done
fi

# mpm_prefork.conf
f_mpm_prefork="/etc/apache2/mods-available/mpm_prefork.conf"

if [ -f ".${f_mpm_prefork}" ]; then
  cp -v ".${f_mpm_prefork}" "${f_mpm_prefork}"
else
  if [ -z "$(cat "${f_mpm_prefork}" | egrep '^[#\t ]{0,}ServerLimit\s{1,}')" ]; then
    sed -i -E \
      -e "/<IfModule mpm_prefork_module>/,/<\/IfModule>/{ 
        s/^([#\t ]{0,})(MaxRequestWorkers\s{1,}.*)/\1\2\n\1Temp_\2/;
        s/Temp_MaxRequestWorkers/ServerLimit/;
      }" \
      "${f_mpm_prefork}"
  fi
  sed -i -E \
    -e "/<IfModule mpm_prefork_module>/,/<\/IfModule>/{ 
      s/^([#\t ]{0,}StartServers\s{1,}).*/\1${STARTSERVERS}/;
      s/^([#\t ]{0,}MinSpareServers\s{1,}).*/\1${MINSPARESERVERS}/;
      s/^([#\t ]{0,}MaxSpareServers\s{1,}).*/\1${MAXSPARESERVERS}/;
      s/^([#\t ]{0,}MaxRequestWorkers\s{1,}).*/\1${MAXREQUESTWORKERS}/;
      s/^([#\t ]{0,}ServerLimit\s{1,}).*/\1${SERVERLIMIT}/;
      s/^([#\t ]{0,}MaxConnectionsPerChild\s{1,}).*/\1${MAXCONNECTIONSPERCHILD}/;
    }" \
    "${f_mpm_prefork}"
fi

SERVERNAME="localhost"

# 000-default configure
f_80="/etc/apache2/sites-available/000-default.conf"

if [ -f ".${f_80}" ]; then
  cp -v ".${f_80}" "${f_80}"
else
  if [ -z "$(cat "${f_80}" | egrep '^[#\t ]{0,}ServerName\s{1,}')" ]; then
    sed -i -E \
      -e "s/^([#\t ]{0,})(ServerAdmin\s{1,}.*)/\1\2\n\1Temp_\1/" \
      -e "s/Temp_ServerAdmin/ServerName/" \
      "${f_80}"
  fi
  sed -i -E \
    -e "s/^[#\t ]{0,}(ServerName)\s{1,}/\1 ${SERVERNAME}/" \
    "${f_80}"
fi

# 000-default-ssl configure
APACHE2_HTTPS="$(getPkgCnf -rs="\[APACHE2\]" -fs="=" -s="APACHE2_HTTPS")"

if [ "${APACHE2_HTTPS^^}" == "ON" ]; then
  f_443="/etc/apache2/sites-available/000-default-ssl.conf"

  if [ -f ".${f_443}" ]; then
    cp -v ".${f_443}" "${f_443}"
  else
    if [ -z "$(cat "${f_443}" | egrep '^[#\t ]{0,}ServerName\s{1,}')" ]; then
      sed -i -E \
        -e "s/^([#\t ]{0,})(ServerAdmin\s{1,}.*)/\1\2\n\1Temp_\1/" \
        -e "s/Temp_ServerAdmin/ServerName/" \
        "${f_443}"
    fi
    sed -i -E \
      -e "s/^[#\t ]{0,}(ServerName)\s{1,}/\1 ${SERVERNAME}/" \
      "${f_443}"
  fi

  # Enable site available
  if [ -z "$(a2query -s | awk '{print $1}' | egrep "^000-default-ssl$")" ]; then
    cd /etc/apache2/sites-available
    a2ensite 000-default-ssl.conf
  fi
fi

# Reloading the service.
systemctl reload apache2

echo
echo "${PKGNAME^} configuration is complete."
