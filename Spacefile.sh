#
# Copyright 2016 Blockie AB
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

clone file

#================================
# OS_DEP_INSTALL
#
# Do nothing, but conform to /_install/ pattern.
#
#================================
OS_DEP_INSTALL ()
{
    SPACE_CMDDEP="PRINT"
    PRINT "No particular dependencies." "success"
}

#================
#
# Get the OS identification and package manager.
#
# env:
#   _OSTYPE
#   _OSPKGMGR
#   _OSHOME - Users home dir.
#   _OSCWD - Current CWD.
#================
OS_ID ()
{
    _OSTYPE="gnu"
    _OSHOME="/home"
    _OSCWD="$(pwd)"
    _OSPKGMGR=
    _OSINIT="sysvinit"

    if command -v "systemctl" >/dev/null; then
        _OSINIT="systemd"
    fi

    if [ "${_OSCWD}" = "/" ]; then
        # We'll conform the root directory to not end with slash,
        # since other directories do not end with slash.
        _OSCWD="/."
    fi

    [ -f "/etc/debian_version" ] && _OSPKGMGR="apt"
    [ -f "/etc/arch-release" ] && _OSPKGMGR="pacman"
    [ -d "/etc/yum" ] && _OSPKGMGR="yum"
    [ -f "/etc/redhat-release" ] && _OSPKGMGR="yum"
    [ -f "/etc/alpine-release" ] && _OSPKGMGR="apk"
    # TODO:
    [ -f "/etc/mac-attack" ] &&  { _OSTYPE="darwin"; _OSHOME="/User"; _OSPKGMGR="brew"; }

    return 0
}

#=============
#
# Show some information about the current OS.
#
#=============
OS_INFO ()
{
    SPACE_CMDDEP="OS_ID PRINT"

    local _OSTYPE='' _OSPKGMGR='' _OSHOME='' _OSCWD='' _OSINIT=''
    OS_ID

    PRINT "OS type: ${_OSTYPE}."
    PRINT "OS init system: ${_OSINIT}."
    PRINT "OS package manager: ${_OSPKGMGR}."
    PRINT "OS home directory: ${_OSHOME}."
    PRINT "Current directory: ${_OSCWD}."
}

#=============
#
# Check if program is installed,
# if not installed then install it's package if provided.
#
#=============
OS_IS_INSTALLED ()
{
    SPACE_SIGNATURE="program [pkg]"
    SPACE_CMDDEP="OS_INSTALL_PKG PRINT"

    local program="${1}"
    shift

    local pkg="${1-}"
    shift $(( $# > 0 ? 1 : 0 ))

    PRINT "Check if ${program} is installed." "debug"
    if command -v "${program}" >/dev/null; then
        PRINT "Yes, ${program} is installed." "debug"
        return 0
    else
        if [ "${pkg}" = "" ]; then
            PRINT "No, ${program} is not installed." "error"
            return 1
        fi
        PRINT "No, ${program} is not installed. Attempting installation..." "info"
        OS_INSTALL_PKG "${pkg}"
        return $?
    fi
}

#================
# _OS_PKG_TRANSLATE
#
# Translates Debian style package names into
# the current OS package manager naming.
#
# Depends on that OS_ID has been called prior.
# Function expecxts ${pkg} and will alter it.
#
#================
_OS_PKG_TRANSLATE ()
{
    # This function should be further added to
    # to handle more packages.
    if [ "${_OSPKGMGR}" = "apk" ]; then
        if [ "${pkg}" = "openssh-server" ]; then
            pkg="openssh"
        elif [ "${pkg}" = "openssh-client" ]; then
            pkg="openssh"
        fi
    elif [ "${_OSPKGMGR}" = "yum" ]; then
        if [ "${pkg}" = "coreutils" ]; then
            pkg="xtra-utils"
        fi
    fi
}

#================
#
# Install a package.
#
# Provide only one package at a time for
# the translatio to work.
# Give the Debian style name of packages
# and the function will attempt to translate
# it to the current package managers name for it.
#
#================
OS_INSTALL_PKG ()
{
    SPACE_SIGNATURE="pkg"
    SPACE_CMDDEP="OS_ID _OS_PKG_TRANSLATE OS_UPDATE PRINT"

    local pkg="${1}"
    shift

    PRINT "Install pkg (untranslated): ${pkg}." "debug"

    local _OSTYPE='' _OSPKGMGR='' _OSHOME='' _OSCWD='' _OSINIT=''
    OS_ID
    _OS_PKG_TRANSLATE

    local SUDO=
    [ "$(id -u)" -gt 0 ] && SUDO="sudo"

    PRINT "Install package: ${pkg}." "info"

    if [ "${_OSPKGMGR}" = "apt" ]; then
        ${SUDO} apt-get -y install "${pkg}"
        if [ "$?" -eq 100 ]; then
            OS_UPDATE
            ${SUDO} apt-get -y install "${pkg}"
        fi
    elif [ "${_OSPKGMGR}" = "pacman" ]; then
        ${SUDO} pacman -S "${pkg}"
        if [ "$?" -gt 0 ]; then
            OS_UPDATE
            ${SUDO} pacman -S "${pkg}"
        fi
    elif [ "${_OSPKGMGR}" = "yum" ]; then
        ${SUDO} yum install "${pkg}"
    elif [ "${_OSPKGMGR}" = "apk" ]; then
        ${SUDO} apk add "${pkg}"
        if [ "$?" -gt 0 ]; then
            OS_UPDATE
            ${SUDO} apk add "${pkg}"
        fi
    elif [ "${_OSPKGMGR}" = "brew" ]; then
        ${SUDO} brew install "${pkg}"
        if [ "$?" -gt 0 ]; then
            OS_UPDATE
            ${SUDO} brew install "${pkg}"
        fi
    else
        PRINT "Could not determine what package manager is being used in the OS." "error"
        return 1
    fi

    if [ "$?" -gt 0 ]; then
        PRINT "Could not install ${pkg}." "error"
        return 1
    fi

    PRINT "Package: ${pkg}, installed successfully!" "success"
}

#=======================
# OS_UPDATE
#
# Update the system package lists.
#
# env:
#   $SUDO: if not run as root set SUDO=sudo
#
#=======================
OS_UPDATE ()
{
    SPACE_CMDDEP="OS_ID PRINT"

    local _OSTYPE='' _OSPKGMGR='' _OSHOME='' _OSCWD='' _OSINIT=''
    OS_ID

    local SUDO=
    [ "$(id -u)" -gt 0 ] && SUDO="sudo"

    PRINT "Update package lists." "info"

    if [ "${_OSPKGMGR}" = "apt" ]; then
        ${SUDO} apt-get update -y
    elif [ "${_OSPKGMGR}" = "pacman" ]; then
        ${SUDO} pacman -Sy
    elif [ "${_OSPKGMGR}" = "yum" ]; then
        :
    elif [ "${_OSPKGMGR}" = "apk" ]; then
        ${SUDO} apk update
    elif [ "${_OSPKGMGR}" = "brew" ]; then
        ${SUDO} brew update
    else
        PRINT "Could not determine what package manager is being used in the OS." "error"
        return 1
    fi

    if [ "$?" -gt 0 ]; then
        PRINT "Could not update package lists." "error"
        return 1
    fi
}

#=======================
# OS_UPGRADE
#
# Upgrade the system.
#
# env:
#   $SUDO: if not run as root set SUDO=sudo
#
#=======================
OS_UPGRADE ()
{
    SPACE_CMDDEP="OS_ID OS_UPDATE PRINT"

    OS_UPDATE
    if [ "$?" -gt 0 ]; then
        return 1
    fi

    local _OSTYPE='' _OSPKGMGR='' _OSHOME='' _OSCWD='' _OSINIT=''
    OS_ID

    local SUDO=
    [ "$(id -u)" -gt 0 ] && SUDO="sudo"

    PRINT "Upgrade OS..." "info"

    if [ "${_OSPKGMGR}" = "apt" ]; then
        ${SUDO} apt-get -y upgrade
    elif [ "${_OSPKGMGR}" = "pacman" ]; then
        ${SUDO} pacman -Syu
    elif [ "${_OSPKGMGR}" = "yum" ]; then
        ${SUDO} yum update -y
    elif [ "${_OSPKGMGR}" = "apk" ]; then
        ${SUDO} apk upgrade
    elif [ "${_OSPKGMGR}" = "brew" ]; then
        ${SUDO} brew upgrade
    else
        PRINT "Could not determine what package manager is being used in the OS." "error"
        return 1
    fi

    if [ "$?" -gt 0 ]; then
        PRINT "Could not upgrade OS." "error"
        return 1
    fi
}

OS_SERVICE ()
{
    SPACE_SIGNATURE="service action"
    SPACE_CMDDEP="PRINT OS_ID"
    SPACE_CMDENV="SUDO=\${SUDO-}"

    local service="${1}"
    shift

    local action="${1}"
    shift

    PRINT "Service ${service}, ${action}." "info"

    local _OSTYPE='' _OSPKGMGR='' _OSHOME='' _OSCWD='' _OSINIT=''
    OS_ID

    local SUDO="${SUDO-}"
    if [ "${_OSINIT}" = "systemd" ]; then
        ${SUDO} systemctl "${action}" "${service}"
    elif [ "${_OSINIT}" = "sysvinit" ]; then
        ${SUDO} "/etc/init.d/${service}" "${action}"
    else
        PRINT "Could not determine what init service is being used in the OS." "error"
        return 1
    fi
}

#=======================
# OS_REBOOT
#
# Reboot the system.
#
# env:
#   $SUDO: if not run as root set SUDO=sudo
#
#=======================
OS_REBOOT ()
{
    SPACE_CMDDEP="PRINT OS_ID"
    SPACE_CMDENV="SUDO=\${SUDO-}"

    PRINT "Reboot system now." "info"

    local _OSTYPE='' _OSPKGMGR='' _OSHOME='' _OSCWD='' _OSINIT=''
    OS_ID

    local SUDO="${SUDO-}"
    if [ "${_OSINIT}" = "systemd" ]; then
        ${SUDO} systemctl reboot
    elif [ "${_OSINIT}" = "sysvinit" ]; then
        ${SUDO} reboot now
    else
        PRINT "Could not determine what init service is being used in the OS." "error"
        return 1
    fi
}

#=======================
# OS_USER_EXIST
#
# Check if a user does exist.
#
# Exits with status 0 if the users does exist, else with status 1.
#
# positional args:
#   user: the name if the user to lookup.
#
#=======================
OS_USER_EXIST ()
{
    SPACE_SIGNATURE="user"
    SPACE_CMDDEP="PRINT"

    local targetuser="${1}"
    shift

    PRINT "Check if user ${targetuser} exists." "debug"

    id -u "${targetuser}" >/dev/null 2>&1
    if [ "$?" -eq 0 ]; then
        PRINT "User does exist." "debug"
        return 0
    else
        PRINT "User does not exist." "debug"
        return 1
    fi
}

#=======================
# OS_GROUP_EXIST
#
# Check if a group does exist.
#
# Exits with status 0 if the group does exist, else with status 1.
#
# positional args:
#   user: the name if the user to lookup.
#
#=======================
OS_GROUP_EXIST ()
{
    SPACE_SIGNATURE="group"
    SPACE_CMDDEP="PRINT FILE_GREP"

    local group="${1}"
    shift

    PRINT "Check if group ${group} exists." "debug"

    FILE_GREP "^${group}.*\$" "/etc/group" "1" "ge" >/dev/null
    if [ "$?" -eq 0 ]; then
        PRINT "Group does exist." "debug"
        return 0
    else
        PRINT "Group does not exist." "debug"
        return 1
    fi
}

#=======================
# OS_CREATE_USER
#
# Create passwordless user and install ssh key for it.
#
# env:
#   $SUDO: if not run as root set SUDO=sudo
#
# positional args:
#   user: The name of the user to create.
#   sshpubkeyfile: Path of the pub key file to install for the user.
#
#=======================
OS_CREATE_USER ()
{
    SPACE_SIGNATURE="targetuser sshpubkeyfile"
    SPACE_CMDREDIR="<${2}"
    SPACE_CMDDEP="PRINT FILE_CHMOD FILE_MKDIRP FILE_PIPE_WRITE FILE_CHOWNR OS_ID OS_ADD_USER"
    SPACE_CMDENV="SUDO=\${SUDO-}"

    local targetuser="${1}"
    shift

    # This is used on SPACE_CMDREDIR.
    # shellcheck disable=2034
    local sshpubkeyfile="${1}"
    shift

    PRINT "Create ${targetuser}." "debug"

    # shellcheck disable=2034
    local _OSTYPE='' _OSPKGMGR='' _OSHOME='' _OSCWD='' _OSINIT=''
    OS_ID

    local SUDO="${SUDO-}"
    local home="${_OSHOME}/${targetuser}"
    OS_ADD_USER "${targetuser}" "${home}" &&
    FILE_CHMOD "700" "${home}" &&
    FILE_MKDIRP "${home}/.ssh" &&
    FILE_CHMOD "700" "${home}/.ssh" &&
    FILE_PIPE_WRITE "${home}/.ssh/authorized_keys" &&
    FILE_CHMOD "600" "${home}/.ssh/authorized_keys" &&
    FILE_CHOWNR "${targetuser}:${targetuser}" "${home}"

    if [ "$?" -gt 0 ]; then
        PRINT "Could not create user: ${targetuser}." "error"
        return 1
    fi
}

#=======================
# OS_ADD_USER
#
# Add a user, with a home directory.
#
#=======================
OS_ADD_USER ()
{
    SPACE_SIGNATURE="user home shell"
    SPACE_CMDENV="SUDO=\${SUDO-}"

    local targetuser="${1}"
    shift

    local home="${1}"
    shift

    local shpath="${1}"
    shift $(( $# > 0 ? 1 : 0 ))

    if [ "${shpath}" = "" ]; then
        shpath="$(command -v bash)"
        if [ "$?" -gt 0 ]; then
            shpath="$(command -v sh)"
        fi
    fi

    local SUDO="${SUDO-}"

    if command -v "useradd" >/dev/null; then
        ${SUDO} useradd -m -d "${home}" -s "${shpath}" -U "${targetuser}"
    elif command -v "adduser" >/dev/null; then
        ${SUDO} adduser -D -h "${home}" -s "${shpath}" "${targetuser}"
    else
        PRINT "No useradd/adduser installed." "error"
        return 1
    fi
}

#=======================
# OS_MKSUDO_USER
#
# Make a user passwordless SUDO.
#
# env:
#   $SUDO: if not run as root set SUDO=sudo
#
# positional args:
#   targetuser: The name of the user to make into sudo user.
#
#=======================
OS_MKSUDO_USER ()
{
    SPACE_SIGNATURE="targetuser"
    SPACE_CMDDEP="PRINT FILE_ROW_PERSIST OS_USER_ADD_GROUP OS_GROUP_EXIST"
    SPACE_CMDENV="SUDO=\${SUDO-}"

    local targetuser="${1}"
    shift

    PRINT "mksudo ${targetuser}." "info"

    local SUDO="${SUDO-}"
    OS_GROUP_EXIST "sudo"
    if [ "$?" -eq 0 ]; then
        PRINT "Add user to sudo group." "debug"
        OS_USER_ADD_GROUP "${targetuser}" "sudo"
    fi

    FILE_ROW_PERSIST "${targetuser} ALL=(ALL:ALL) NOPASSWD: ALL" "/etc/sudoers"

    if [ "$?" -gt 0 ]; then
        PRINT "Could not mksudo user: ${targetuser}." "error"
        return 1
    fi
}

#=======================
# OS_USER_ADD_GROUP
#
#
#=======================
OS_USER_ADD_GROUP ()
{
    SPACE_SIGNATURE="targetuser group"
    SPACE_CMDENV="SUDO=\${SUDO-}"

    local targetuser="${1}"
    shift

    local group="${1}"
    shift

    local SUDO="${SUDO-}"
    if command -v "usermod" >/dev/null; then
        ${SUDO} usermod -aG "${group}" "${targetuser}"
    elif command -v "addgroup" >/dev/null; then
        ${SUDO} addgroup "${targetuser}" "${group}"
    fi
}

#=======================
# OS_MOTD
#
# Copy a motd file into the system.
# motd is the greeting text that shows when you login.
#
# env:
#   $SUDO: if not run as root set SUDO=sudo
#
# positional args;
#   motdfile: The path of the motd file ti upload.
#
#=======================
OS_MOTD ()
{
    SPACE_SIGNATURE="motdfile"
    # shellcheck disable=2034
    SPACE_CMDREDIR="<${1}"
    SPACE_CMDDEP="FILE_PIPE_WRITE PRINT"

    local motdfile="${1}"
    shift

    PRINT "Replace /etc/motd with ${motdfile}." "debug"

    FILE_PIPE_WRITE "/etc/motd"
}

#=======================
# OS_DISABLE_ROOT
#
# Disable root from logging in both via ssh and physically.
#
# env:
#   $SUDO: if not run as root set SUDO=sudo
#
#=======================
OS_DISABLE_ROOT ()
{
    SPACE_CMDDEP="PRINT FILE_SED FILE_ROW_PERSIST OS_SERVICE"
    SPACE_CMDENV="SUDO=\${SUDO-}"

    PRINT "Inactivating root account." "info"

    if [ "$(id -u)" -eq 0 ]; then
        PRINT "Do not run this as root." "error"
        return 1
    fi

    local SUDO="${SUDO-}"
    ${SUDO} passwd -d root &&
    FILE_SED "s/^PermitRootLogin.*$/PermitRootLogin no/g" "/etc/ssh/sshd_config" &&
    FILE_ROW_PERSIST "PermitRootLogin no" "/etc/ssh/sshd_config" &&
    OS_SERVICE "sshd" "reload"

    if [ "$?" -gt 0 ]; then
        PRINT "Could not inactivate root." "error"
        return 1
    fi
}

#=======================
# OS_DISABLE_USER
#
# Disable a user from logging in both via ssh and physically.
#
# env:
#   $SUDO: if not run as root set SUDO=sudo
#
# positional args:
#   targetuser: The name of the user to make inactive.
#
#=======================
OS_DISABLE_USER ()
{
    SPACE_SIGNATURE="targetuser"
    SPACE_CMDDEP="PRINT FILE_ROW_PERSIST OS_SERVICE"
    SPACE_CMDENV="SUDO=\${SUDO-}"

    local targetuser="${1}"
    shift

    if [ "$(whoami)" = "${targetuser}" ]; then
        PRINT "This is you! Sawing of the branch you're sitting on?" "error"
        return 1
    fi

    PRINT "Inactivate user ${targetuser}." "info"

    local SUDO="${SUDO-}"
    ${SUDO} passwd -d "${targetuser}" &&
    FILE_ROW_PERSIST "DenyUsers ${targetuser}" "/etc/ssh/sshd_config" &&
    OS_SERVICE "sshd" "reload"

    if [ "$?" -gt 0 ]; then
        PRINT "Could not inactivate user: ${targetuser}." "error"
        return 1
    fi
}

#============
# OS_SHELL
#
# env:
#   $SUDO:
#
#
#============
OS_SHELL ()
{
    # shellcheck disable=2034
    SPACE_SIGNATURE="[shell]"
    # shellcheck disable=2034
    SPACE_CMDDEP="PRINT"
    # shellcheck disable=2034
    SPACE_CMDENV="SUDO=\${SUDO-}"

    local shell="${1:-sh}"
    shift $(( $# > 0 ? 1 : 0 ))

    PRINT "Enter shell: ${shell}." "debug"

    local SUDO="${SUDO-}"
    # shellcheck disable=2086
    ${SUDO} ${shell}
}
