#
# lsb_release command is only work for Ubuntu platform but not in centos
# so you can get details from /etc/os-release file
# following command will give you the both OS name and version-
#
# https://askubuntu.com/questions/459402/how-to-know-if-the-running-platform-is-ubuntu-or-centos-with-help-of-a-bash-scri

# Get the operating system name.
function getOs() {
  echo "$(cat /etc/os-release | awk -F '=' '/^NAME/{print $2}' | awk '{print $1}' | tr -d '"')"
}

# Obtain operating system version information.
function getOsVer() {
  echo "$(cat /etc/os-release | awk -F '=' '/^VERSION_ID/{print $2}' | awk '{print $1}' | tr -d '"')"
}

# Detect if the system is Ubuntu.
function isUbuntu() {
  if [ "$(getOs)" == "Ubuntu" ]; then echo "operating system is Ubuntu"; fi
}

# Detect if the centos is Ubuntu.
function isCentos() {
  if [ "$(getOs)" == "CentOS" ]; then echo "operating system is CentOS"; fi
}

# Get ubuntu operating system version information.
function getUbuntuVer() {
  echo "$(getOsVer)"
}

# Get centos operating system version information.
function getCentosVer() {
  echo "$(getOsVer)"
}

# Detect if a package is installed.
function isPkg() {
  if [ ! -z "$(dpkg-query -l | grep "$1" 2>/dev/null)" ]; then echo "The $1 package is installed."; fi
}

# Detect if apache2 is installed.
function isApache2() {
  local funcname=""
  funcname="${FUNCNAME[0]/is}"
  funcname="${funcname,,}"
  if [ ! -z "$(isPkg "${funcname}")" ]; then echo "The ${funcname} package is installed."; fi
}

# Detect if mariadb is installed.
function isMariadb() {
  local funcname=""
  funcname="${FUNCNAME[0]/is}"
  funcname="${funcname,,}"
  if [ ! -z "$(isPkg "${funcname}")" ]; then echo "The ${funcname} package is installed."; fi
}

# Detect if php is installed.
function isPhp() {
  local funcname=""
  funcname="${FUNCNAME[0]/is}"
  funcname="${funcname,,}"

  if [ ! -z "$(isPkg "${funcname}")" ]; then echo "The ${funcname} package is installed."; fi
}

# Detect if ufw is installed.
function isUfw() {
  local funcname=""
  funcname="${FUNCNAME[0]/is}"
  funcname="${funcname,,}"
  if [ ! -z "$(isPkg "${funcname}")" ]; then echo "The ${funcname} package is installed."; fi
}

# Detect if fail2ban is installed.
function isFail2ban() {
  local funcname=""
  funcname="${FUNCNAME[0]/is}"
  funcname="${funcname,,}"
  if [ ! -z "$(isPkg "${funcname}")" ]; then echo "The ${funcname} package is installed."; fi
}

# Detect if vsftpd is installed.
function isVsftpd() {
  local funcname=""
  funcname="${FUNCNAME[0]/is}"
  funcname="${funcname,,}"
  if [ ! -z "$(isPkg "${funcname}")" ]; then echo "The ${funcname} package is installed."; fi
}

# Detect if sendmail is installed.
function isSendmail() {
  local funcname=""
  funcname="${FUNCNAME[0]/is}"
  funcname="${funcname,,}"
  if [ ! -z "$(isPkg "${funcname}")" ]; then echo "The ${funcname} package is installed."; fi
}

# Get package version information.
function getPkgVer() {
  echo ""
}

# Get the apache2 package version information.
function getApache2Ver() {
  echo ""
}

# Get the mariadb package version information.
function getMariadbVer() {
  echo ""
}

# Get the php package version information.
function getPhpVer() {
  local ver=""
  # PHP_MAJOR_VERSION.PHP_MINOR_VERSION.PHP_RELEASE_VERSION
  ver=$(php -v | awk '/^PHP/{print $2}' | awk -F "-" '{print $1}')
  # Removed release version from PHP version.
  echo "${ver%\.*}"
}

# Get the ufw package version information.
function getUfwVer() {
  echo ""
}

# Get the fail2ban package version information.
function getFail2banVer() {
  echo "$(fail2ban-client --version | awk '/^Fail2Ban.*$/{print $2}' | sed "s/v//")"
}

# Get the vsftpd package version information.
function getVsftpdVer() {
  echo ""
}

# Get the sendmail package version information.
function getSendmailVer() {
  echo ""
}

# Truncate the first and last spaces.
function trim() {
  echo "$1" | sed -E -e 's/^\s+|\s+$//g'
}

# The escape string for regular expressions.
function escapeString() {
  echo "$1" | sed -E \
  -e 's/\%/\\\%/g'\
  -e 's/\+/\\\+/g'\
  -e 's/\-/\\\-/g'\
  -e 's/\./\\\./g'\
  -e 's/\//\\\//g'\
  -e 's/\:/\\\:/g'\
  -e 's/\=/\\\=/g'\
  -e 's/\@/\\\@/g'\
  -e 's/\_/\\\_/g'\
  -e 's/\!/\\\!/g'\
  -e 's/\#/\\\#/g'\
  -e 's/\$/\\\$/g'\
  -e 's/\&/\\\&/g'\
  -e 's/\(/\\\(/g'\
  -e 's/\)/\\\)/g'\
  -e 's/\*/\\\*/g'\
  -e 's/\,/\\\,/g'\
  -e 's/\;/\\\;/g'\
  -e 's/\?/\\\?/g'\
  -e 's/\[/\\\[/g'\
  -e 's/\]/\\\]/g'\
  -e 's/\^/\\\^/g'\
  -e 's/\{/\\\{/g'\
  -e 's/\|/\\\|/g'\
  -e 's/\}/\\\}/g'\
  -e 's/</\\</g'\
  -e 's/>/\\>/g'\
  -e 's/`/\\`/g'\
  -e 's/"/\\"/g'\
  -e "s/'/\\\'/g"
}

# Escape quotes in regular expressions.
function escapeQuote() {
  echo "$1" | sed -e "s/'/\\\'/g" -e 's/"/\\"/g' -e 's/`/\\`/g'
}

# Get the absolute path of the file.
function getAbsPath() {
  local FILENAME="$(basename "$1")"
  local ABSPATH="$(cd "$(dirname "$1")" && pwd)"
  if [ "$1" == "/" ]; then
    ABSPATH="$(cd "$(dirname "./")" && pwd)"
  elif [ "$1" == "../" ]; then
    ABSPATH="$(cd "$(dirname "./")" && pwd)"
    ABSPATH="${ABSPATH%\/*}"
  fi
  if [ -z "$(echo "${FILENAME}" | egrep "[a-zA-Z]")" ]; then
    echo "$ABSPATH"
  else
    echo "$ABSPATH/${FILENAME}"
  fi
}

# Get the absolute directory path of a file.
function getAbsDir() {
  local FILEPATH="$(getAbsPath "$1")"
  if [ -z "$(echo "$1" | egrep "[a-zA-Z]")" ]; then
    echo "${FILEPATH}"
  else
    echo "${FILEPATH%\/*}"
  fi
}

# Use openssl to generate random characters.
function openssl_random() {
  openssl rand -base64 "$1"
}

# Encrypt the character using openssl.
function openssl_encrypt() {
  echo "$1" | openssl base64
}

# Decrypt the character using openssl.
function openssl_decrypt() {
  echo "$1" | openssl base64 -d
}