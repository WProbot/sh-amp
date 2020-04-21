#!/bin/bash
#
# Download and run the latest release version.
# https://github.com/w3src/sh-amp
#
# Usage
# git clone https://github.com/w3src/sh-amp.git
# cd sh-amp
# chmod +x ./ubuntu/18.04/amp-usr.sh
# ./ubuntu/18.04/amp-usr.sh

# Check to see if script is being run as root
if [ "$(whoami)" != 'root' ]; then
  echo "You have no permission to run $0 as non-root user. Use sudo"
  exit
fi

# Check if git is installed
if ! hash git 2>/dev/null; then
  echo -e "Git is not installed! You will need it at some point anyways..."
  echo -e "Exiting, install git first."
  exit 0
fi

set -e # Work even if somebody does "sh thisscript.sh".

function username_exists() {
  if ! cut -d: -f1 /etc/passwd | egrep -q "^$1$"; then
    echo "The user '$1' does not exist."
    exists_username=""
    while [[ -z "$exists_username" ]]; do
      read -p "username: " exists_username
      if ! cut -d: -f1 /etc/passwd | egrep -q "^$exists_username$"; then
        echo "The user '$exists_username' does not exist."
        exists_username=""
      fi
    done
  else
    exists_username="$1"
  fi
}

function username_create() {
  if cut -d: -f1 /etc/passwd | egrep -q "^$1$"; then
    echo "The user '$1' already exists."
    create_username=""
    while [[ -z "$create_username" ]]; do
      read -p "username: " create_username
      if cut -d: -f1 /etc/passwd | egrep -q "^$create_username$"; then
        echo "The user '$create_username' already exists."
        create_username=""
      fi
    done
  else
    create_username="$1"
  fi
}

# Selecting Step
PS3="Choose the next step. (1-8): "
select choice in "Create a new ftp user?" "Allow user root access?" "Change user password?" "Change user home directory?" "Delete an exist user?" "Allow access to the root account?" "Deny access to the root account?" "quit"; do
  case $choice in
  "Create a new ftp user?")
    step="createUserAccount"
    break
    ;;
  "Allow user root access?")
    step="allowUserRootAccess"
    break
    ;;
  "Change user password?")
    step="changeUserPassword"
    break
    ;;
  "Change user home directory?")
    step="changeUserHomeDirectory"
    break
    ;;
  "Delete an exist user?")
    step="deleteUserAccount"
    break
    ;;
  "Allow access to the root account?")
    step="allowRootAccess"
    break
    ;;
  "Deny access to the root account?")
    step="denyRootAccess"
    break
    ;;
  "quit")
    exit
    ;;
  esac
done

if [ $step != "allowRootAccess" ] || [ $step != "denyRootAccess" ]; then
  username=""
  while [[ -z "$username" ]]; do
    read -p "username: " username
  done
fi

if [ $step == "createUserAccount" ]; then
  username_create "$username"
  adduser $create_username
  usermod -a -G www-data "$create_username"
  if ! egrep -q "^$create_username$" /etc/vsftpd.user_list; then
    echo "$create_username" | tee -a /etc/vsftpd.user_list
  else
    echo $create_username " is already in user_list."
  fi
  # Disabling Shell Access
  usermod $create_username -s /bin/ftponly
  echo "New users have been added."
fi

if [ $step == "allowUserRootAccess" ]; then
  username_exists "$username"
  if ! egrep -q "^$exists_username$" /etc/vsftpd.chroot_list; then
    echo "$exists_username" | tee -a /etc/vsftpd.chroot_list
  else
    echo $exists_username " is already in chroot_list."
  fi
  echo "User root access is allowed."
fi

if [ $step == "changeUserPassword" ]; then
  username_exists "$username"
  passwd "$exists_username"
  echo "User password has been changed."
fi

if [ $step == "changeUserHomeDirectory" ]; then
  username_exists "$username"
  userdir=""
  while [[ -z "$userdir" ]]; do
    read -p "user's home directory: " userdir
    if [ ! -d $userdir ]; then
      echo "Directory does not exist."
      while true; do
        read -p "Do you want to create a directory? (y/n) " ansusrmod
        case $ansusrmod in
        y | Y)
          mkdir -p $userdir
          break 2
          ;;
        n | N)
          break
          ;;
        esac
      done
    fi
  done
  chown -R www-data:www-data "$userdir"
  chmod -R 775 "$userdir"
  echo "The user home directory has been changed."
fi

if [ $step == "deleteUserAccount" ]; then
  username_exists "$username"
  deluser --remove-home "$exists_username"
  if egrep -q "^$exists_username$" /etc/vsftpd.user_list; then
    sed -i -E "/^$exists_username$/d" /etc/vsftpd.user_list
  fi
  if egrep -q "^$exists_username$" /etc/vsftpd.chroot_list; then
    sed -i -E "/^$exists_username$/d" /etc/vsftpd.chroot_list
  fi
  echo "The existing user has been deleted."
fi

if [ $step == "allowRootAccess" ]; then
  if egrep -q "^root$" /etc/ftpusers; then
    sed -i -E "/^root$/d" /etc/ftpusers
  fi
  echo "Access to the root account is allowed."
fi

if [ $step == "denyRootAccess" ]; then
  if ! egrep -q "^root$" /etc/ftpusers; then
    echo "root" | sudo tee -a /etc/ftpusers
  fi
  echo "Access to the root account is denied."
fi

printf "\n\nRestarting vsftpd ... \n"
systemctl restart vsftpd