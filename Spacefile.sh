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
# Check for dependencies
#
#================================
OS_DEP_INSTALL ()
{
    SPACE_DEP="PRINT"
    PRINT "No particular dependencies." "ok"
}

#================
# OS_ID
#
# Get the OS identification and package manager.
#
# Expects:
#   _OSTYPE
#   _OSPKGMGR
#   _OSHOME - Users home dir.
#   _OSCWD - Current CWD.
#
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

    # Some releases are more tricky.
    if [ "${_OSPKGMGR}" = "" ]; then
        if command -v "apt-get" >/dev/null; then
            _OSPKGMGR="apt"
        elif command -v "pacman" >/dev/null; then
            _OSPKGMGR="pacman"
        elif command -v "yum" >/dev/null; then
            _OSPKGMGR="yum"
        elif command -v "apk" >/dev/null; then
            _OSPKGMGR="apk"
        elif command -v "brew" >/dev/null; then
            _OSPKGMGR="brew"
            _OSTYPE="darwin"
            _OSHOME="/Users"
            _OSINIT="launchd"
        elif command -v "pkg" >/dev/null; then
            _OSPKGMGR="pkg"
            _OSTYPE="FreeBSD"
            _OSINIT="rc"
        fi
    fi

    return 0
}


# Disable warning about local keyword
# shellcheck disable=SC2039

#=============
# OS_INFO
#
# Show some information about the current OS.
#
#=============
OS_INFO ()
{
    SPACE_DEP="OS_ID PRINT"

    local _OSTYPE=''
    local _OSPKGMGR=''
    local _OSHOME=''
    local _OSCWD=''
    local _OSINIT=''
    OS_ID

    PRINT "OS type: ${_OSTYPE}."
    PRINT "OS init system: ${_OSINIT}."
    PRINT "OS package manager: ${_OSPKGMGR}."
    PRINT "OS home directory: ${_OSHOME}."
    PRINT "Current directory: ${_OSCWD}."
}


# Disable warning about local keyword
# shellcheck disable=SC2039

#=============
# OS_IS_INSTALLED
#
# Check if program is installed.
# If not installed then install its package, if provided.
#
# Parameters:
#   $1: program name
#   $2: package name
#
# Returns:
#   0: program is available
#   0: program is not available and failed to install it
#
#=============
OS_IS_INSTALLED ()
{
    SPACE_SIGNATURE="program [pkg]"
    SPACE_DEP="OS_INSTALL_PKG _OS_PROGRAM_TRANSLATE PRINT"

    local program="${1}"
    shift

    local pkg="${1-}"
    shift $(( $# > 0 ? 1 : 0 ))

    local program2="${program}"

    local _OSTYPE=''
    local _OSPKGMGR=''
    local _OSHOME=''
    local _OSCWD=''
    local _OSINIT=''
    OS_ID

    _OS_PROGRAM_TRANSLATE

    PRINT "Check if ${program} (originally ${program2}) is installed." "debug"
    if command -v "${program}" >/dev/null; then
        PRINT "Available: ${program} is installed." "debug"
        return 0
    else
        if [ "${pkg}" = "" ]; then
            PRINT "Missing: ${program} is not installed."
            return 1
        fi
        PRINT "Missing: ${program} is not installed. Attempting installation..." "info"
        OS_INSTALL_PKG "${pkg}"
        return $?
    fi
}


# Disable warning about local keyword
# shellcheck disable=SC2039

#================
# _OS_PKG_TRANSLATE
#
# Translates Debian style package names into
# the current OS package manager naming.
#
# A translation could be translated into one or many
# package names.
#
# Expects:
#   ${pkg}: package(s) name(s) to adjust
#
#================
_OS_PKG_TRANSLATE ()
{
    local _OSTYPE=''
    local _OSPKGMGR=''
    local _OSHOME=''
    local _OSCWD=''
    local _OSINIT=''
    OS_ID

    local pkg2="${pkg}"
    local p=""
    pkg=""
    for p in ${pkg2}; do
        # This function should be further added to
        # to handle more packages.
        if [ "${_OSPKGMGR}" = "apk" ]; then
            if [ "${p}" = "openssh-server" ]; then
                p="openssh"
            elif [ "${p}" = "openssh-client" ]; then
                p="openssh"
            elif [ "${p}" = "libyaml-dev" ]; then
                p="yaml-dev"
            elif [ "${p}" = "libreadline-dev" ]; then
                p="readline-dev"
            elif [ "${p}" = "libncurses-dev" ]; then
                p="ncurses-dev"
            fi
        elif [ "${_OSPKGMGR}" = "yum" ]; then
            if [ "${p}" = "coreutils" ]; then
                p="xtra-utils"
            #elif [ "${p}" = "lua5.1" ]; then
                #p="lua"
            elif [ "${p}" = "openssh-client" ]; then
                p="openssh-clients"
            elif [ "${p}" = "libyaml-dev" ]; then
                p="libyaml-devel"
            elif [ "${p}" = "libc-dev" ]; then
                p="glibc-devel glibc-headers"
            #elif [ "${p}" = "lua5.1-dev" ]; then
                #p="lua-devel"
            elif [ "${p}" = "libreadline-dev" ]; then
                p="readline-devel"
            elif [ "${p}" = "libncurses-dev" ]; then
                p="ncurses-devel"
            fi
        elif [ "${_OSPKGMGR}" = "pacman" ]; then
            if [ "${p}" = "lua5.1" ]; then
                p="lua51"
            elif [ "${p}" = "lua5.2" ]; then
                p="lua52"
            elif [ "${p}" = "lua5.3" ]; then
                p="lua"  # NOTE: This is dependant on pacman version since one day "lua" will mean "lua5.4", which is not good.
            elif [ "${p}" = "openssh-server" ]; then
                p="openssh"
            elif [ "${p}" = "openssh-client" ]; then
                p="openssh"
            elif [ "${p}" = "libyaml-dev" ]; then
                p="libyaml"
            elif [ "${p}" = "libc-dev" ]; then
                p="linux-api-headers"
            elif [ "${p}" = "lua5.1-dev" ]; then
                p="lua51"
            elif [ "${p}" = "libreadline-dev" ]; then
                p="readline"
            elif [ "${p}" = "libncurses-dev" ]; then
                p="ncurses"
            fi
        fi
        if [ -z "${p}" ]; then
            continue
        fi
        pkg="${pkg:+$pkg }${p}"
    done
}


# Disable warning about local keyword
# shellcheck disable=SC2039

#================
# _OS_PROGRAM_TRANSLATE
#
# Translates Debian style program names into
# the current OS distributions program naming.
#
# Expects:
#   ${program}: program name to translate
#
#================
_OS_PROGRAM_TRANSLATE ()
{
    local _OSTYPE=''
    local _OSPKGMGR=''
    local _OSHOME=''
    local _OSCWD=''
    local _OSINIT=''
    OS_ID

    # This function should be further added to
    # to handle more programs.
    if [ "${_OSPKGMGR}" = "apk" ]; then
        :
    elif [ "${_OSPKGMGR}" = "yum" ]; then
        if [ "${program}" = "lua5.1" ]; then
            program="lua"
        fi
    elif [ "${_OSPKGMGR}" = "pacman" ]; then
        :
    fi
}


# Disable warning about indirectly checking status code
# shellcheck disable=SC2181
# Disable warning about local keyword
# shellcheck disable=SC2039
# Disable warning about ${pkg}: word splitting is intended
# shellcheck disable=SC2086

#================
# OS_INSTALL_PKG
#
# Install one or more packages.
#
# Give the Debian style name of packages
# and the function will attempt to translate
# it to the current package managers name for it.
#
# Parameters:
#   $1: package(s) name(s)
#
# Returns:
#   0: success
#   1: failed to install package either due to unknown package manager or package name
#
#================
OS_INSTALL_PKG ()
{
    SPACE_SIGNATURE="pkg"
    SPACE_DEP="OS_ID _OS_PKG_TRANSLATE OS_UPDATE PRINT"
    SPACE_ENV="SUDO=\${SUDO-}"

    local pkg="${1}"
    shift

    PRINT "Install pkg(s) (untranslated): ${pkg}." "debug"

    local _OSTYPE=''
    local _OSPKGMGR=''
    local _OSHOME=''
    local _OSCWD=''
    local _OSINIT=''
    OS_ID

    _OS_PKG_TRANSLATE

    if [ "${pkg}" = "" ]; then
        PRINT "Package has no target for pkg mgr: ${_OSPKGMGR}."
        return 0
    fi

    if [ "$(id -u)" -gt 0 ]; then
        local SUDO="${SUDO-}"
    else
        local SUDO=
    fi

    PRINT "Install package(s) using ${_OSPKGMGR}: ${pkg}." "info"

    if [ "${_OSPKGMGR}" = "apt" ]; then
        ${SUDO} apt-get -y install ${pkg}
        if [ "$?" -eq 100 ]; then
            OS_UPDATE
            ${SUDO} apt-get -y install ${pkg}
        fi
    elif [ "${_OSPKGMGR}" = "pacman" ]; then
        ${SUDO} pacman -Syu --noconfirm ${pkg}
        if [ "$?" -gt 0 ]; then
            OS_UPDATE
            ${SUDO} pacman -Syu --noconfirm ${pkg}
        fi
    elif [ "${_OSPKGMGR}" = "yum" ]; then
        ${SUDO} yum -y install ${pkg}
    elif [ "${_OSPKGMGR}" = "apk" ]; then
        ${SUDO} apk add ${pkg}
        if [ "$?" -gt 0 ]; then
            OS_UPDATE
            ${SUDO} apk add ${pkg}
        fi
    elif [ "${_OSPKGMGR}" = "brew" ]; then
        ${SUDO} brew install ${pkg}
        if [ "$?" -gt 0 ]; then
            OS_UPDATE
            ${SUDO} brew install ${pkg}
        fi
    elif [ "${_OSPKGMGR}" = "pkg" ]; then
        ${SUDO} pkg install ${pkg}
        if [ "$?" -gt 0 ]; then
            OS_UPDATE
            ${SUDO} pkg install ${pkg}
        fi
    else
        PRINT "Could not determine what package manager is being used in the OS." "error"
        return 1
    fi

    if [ "$?" -gt 0 ]; then
        PRINT "Could not install ${pkg}." "error"
        return 1
    fi

    PRINT "Package(s): ${pkg}, installed successfully!" "ok"
}


# Disable warning about indirectly checking status code
# shellcheck disable=SC2181
# Disable warning about local keyword
# shellcheck disable=SC2039

#=======================
# OS_UPDATE
#
# Update the system package lists.
#
# Expects:
#   $SUDO: if not run as root set `SUDO=sudo`
#
#=======================
OS_UPDATE ()
{
    SPACE_DEP="OS_ID PRINT"
    SPACE_ENV="SUDO=\${SUDO-}"

    local _OSTYPE=''
    local _OSPKGMGR=''
    local _OSHOME=''
    local _OSCWD=''
    local _OSINIT=''
    OS_ID

    if [ "$(id -u)" -gt 0 ]; then
        local SUDO="${SUDO-}"
    else
        local SUDO=
    fi

    PRINT "Update package lists." "info"

    if [ "${_OSPKGMGR}" = "apt" ]; then
        ${SUDO} apt-get update -y
    elif [ "${_OSPKGMGR}" = "pacman" ]; then
        ${SUDO} pacman --noconfirm -Sy
    elif [ "${_OSPKGMGR}" = "yum" ]; then
        :
    elif [ "${_OSPKGMGR}" = "apk" ]; then
        ${SUDO} apk update
    elif [ "${_OSPKGMGR}" = "brew" ]; then
        ${SUDO} brew update
    elif [ "${_OSPKGMGR}" = "pkg" ]; then
        ${SUDO} pkg update
    else
        PRINT "Could not determine what package manager is being used in the OS." "error"
        return 1
    fi

    if [ "$?" -gt 0 ]; then
        PRINT "Could not update package lists." "error"
        return 1
    fi
}


# Disable warning about indirectly checking status code
# shellcheck disable=SC2181
# Disable warning about local keyword
# shellcheck disable=SC2039

#=======================
# OS_UPGRADE
#
# Upgrade the system.
#
# Expects:
#   $SUDO: if not run as root set `SUDO=sudo`
#
# Returns:
#   Non-zero on error.
#
#=======================
OS_UPGRADE ()
{
    SPACE_DEP="OS_ID OS_UPDATE PRINT"
    SPACE_ENV="SUDO=\${SUDO-}"

    OS_UPDATE
    if [ "$?" -gt 0 ]; then
        return 1
    fi

    local _OSTYPE=''
    local _OSPKGMGR=''
    local _OSHOME=''
    local _OSCWD=''
    local _OSINIT=''
    OS_ID

    if [ "$(id -u)" -gt 0 ]; then
        local SUDO="${SUDO-}"
    else
        local SUDO=
    fi

    PRINT "Upgrade OS..." "info"

    if [ "${_OSPKGMGR}" = "apt" ]; then
        ${SUDO} apt-get -y upgrade
    elif [ "${_OSPKGMGR}" = "pacman" ]; then
        ${SUDO} pacman --noconfirm -Syu
    elif [ "${_OSPKGMGR}" = "yum" ]; then
        ${SUDO} yum update -y
    elif [ "${_OSPKGMGR}" = "apk" ]; then
        ${SUDO} apk upgrade
    elif [ "${_OSPKGMGR}" = "brew" ]; then
        ${SUDO} brew upgrade
    elif [ "${_OSPKGMGR}" = "pkg" ]; then
        ${SUDO} pkg upgrade
    else
        PRINT "Could not determine what package manager is being used in the OS." "error"
        return 1
    fi

    if [ "$?" -gt 0 ]; then
        PRINT "Could not upgrade OS." "error"
        return 1
    fi
}


# Disable warning about local keyword
# shellcheck disable=SC2039

#=======================
# OS_SERVICE
#
# Control a service.
#
# Parameters:
#   $1: service name
#   $2: action
#
# Expects:
#   $SUDO: if not run as root set `SUDO=sudo`
#
# Returns:
#   0: success
#   1: failure
#
#=======================
OS_SERVICE ()
{
    SPACE_SIGNATURE="service action"
    SPACE_DEP="PRINT OS_ID"
    SPACE_ENV="SUDO=\${SUDO-}"

    local service="${1}"
    shift

    local action="${1}"
    shift

    PRINT "Service ${service}, ${action}." "info"

    local _OSTYPE=''
    local _OSPKGMGR=''
    local _OSHOME=''
    local _OSCWD=''
    local _OSINIT=''
    OS_ID

    local SUDO="${SUDO-}"
    if [ "${_OSINIT}" = "systemd" ]; then
        ${SUDO} systemctl "${action}" "${service}"
    elif [ "${_OSINIT}" = "sysvinit" ]; then
        ${SUDO} "/etc/init.d/${service}" "${action}"
    elif [ "${_OSINIT}" = "launchd" ]; then
        ${SUDO} launchctl "${action}" "${service}"
    elif [ "${_OSINIT}" = "rc" ]; then
        ${SUDO} "/etc/rc.d/${service}" "${action}"
    else
        PRINT "Could not determine what init service is being used in the OS." "error"
        return 1
    fi
}


# Disable warning about local keyword
# shellcheck disable=SC2039

#=======================
# OS_REBOOT
#
# Reboot the system.
#
# Expects:
#   $SUDO: if not run as root set `SUDO=sudo`
#
#=======================
OS_REBOOT ()
{
    SPACE_DEP="PRINT OS_ID"
    SPACE_ENV="SUDO=\${SUDO-}"

    PRINT "Reboot system now." "info"

    local _OSTYPE=''
    local _OSPKGMGR=''
    local _OSHOME=''
    local _OSCWD=''
    local _OSINIT=''
    OS_ID

    local SUDO="${SUDO-}"
    if [ "${_OSINIT}" = "systemd" ]; then
        ${SUDO} systemctl reboot
    elif [ "${_OSINIT}" = "sysvinit" ] \
      || [ "${_OSINIT}" = "launchd" ]  \
      || [ "${_OSINIT}" = "rc" ]; then
        ${SUDO} reboot now
    else
        PRINT "Could not determine what init service is being used in the OS." "error"
        return 1
    fi
}


# Disable warning about indirectly checking status code
# shellcheck disable=SC2181

#=======================
# OS_USER_EXIST
#
# Check if a user does exist.
#
# Parameters:
#   $1: the name of the user to lookup.
#
# Returns:
#   0: users does exist
#   1: failure. User does NOT exist
#
#=======================
OS_USER_EXIST ()
{
    SPACE_SIGNATURE="user"
    SPACE_DEP="PRINT"

    # shellcheck disable=SC2039
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


# Disable warning about indirectly checking status code
# shellcheck disable=SC2181

#=======================
# OS_GROUP_EXIST
#
# Check if a group does exist.
#
# Parameters:
#   $1: the name of the group to lookup.
#
# Returns:
#   0: group does exist
#   1: failure. Group does NOT exist
#
#=======================
OS_GROUP_EXIST ()
{
    SPACE_SIGNATURE="group"
    SPACE_DEP="PRINT FILE_GREP"

    # shellcheck disable=SC2039
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


# Disable warning about indirectly checking status code
# shellcheck disable=SC2181
# Disable warning about local keyword
# shellcheck disable=SC2039

#=======================
# OS_CREATE_USER
#
# Create passwordless user and install ssh key for it.
#
# Parameters:
#   $1: The name of the user to create.
#   $2: Path of the pub key file to install for the user.
#
# Expects:
#   $SUDO: if not run as root set `SUDO=sudo`
#
# Returns:
#   0: success
#   1: failure
#
#=======================
OS_CREATE_USER ()
{
    SPACE_SIGNATURE="targetuser sshpubkeyfile"
    SPACE_REDIR="<${2}"
    SPACE_DEP="PRINT FILE_CHMOD FILE_MKDIRP FILE_PIPE_WRITE FILE_CHOWNR OS_ID OS_ADD_USER"
    SPACE_ENV="SUDO=\${SUDO-}"

    local targetuser="${1}"
    shift

    # This is used on SPACE_REDIR.
    # shellcheck disable=2034
    local sshpubkeyfile="${1}"
    shift

    PRINT "Create ${targetuser}." "debug"

    # shellcheck disable=2034
    local _OSTYPE=''
    local _OSPKGMGR=''
    local _OSHOME=''
    local _OSCWD=''
    local _OSINIT=''
    OS_ID

    local SUDO="${SUDO-}"
    local home="${_OSHOME}/${targetuser}"
    OS_ADD_USER "${targetuser}" "${home}" "/bin/sh" &&
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


# Disable warning about indirectly checking status code
# shellcheck disable=SC2181
# Disable warning about local keyword
# shellcheck disable=SC2039

#=======================
# OS_ADD_USER
#
# Add a user, with a home directory.
#
# Parameters:
#   $1: user name
#   $2: home path directory
#   $3: shell path
#
# Returns:
#   0: success
#   1: failed to call useradd/adduser
#
#=======================
OS_ADD_USER ()
{
    SPACE_SIGNATURE="user home shell"
    SPACE_ENV="SUDO=\${SUDO-}"

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


# Disable warning about indirectly checking status code
# shellcheck disable=SC2181
# Disable warning about local keyword
# shellcheck disable=SC2039

#=======================
# OS_MKSUDO_USER
#
# Make a user passwordless SUDO.
#
# Parameters:
#   $1: The name of the user to make into sudo user.
#
# Expects:
#   $SUDO: if not run as root set `SUDO=sudo`
#
# Returns:
#   0: success
#   1: failure
#
#=======================
OS_MKSUDO_USER ()
{
    SPACE_SIGNATURE="targetuser"
    SPACE_DEP="PRINT FILE_ROW_PERSIST OS_USER_ADD_GROUP OS_GROUP_EXIST"
    SPACE_ENV="SUDO=\${SUDO-}"

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


# Disable warning about local keyword
# shellcheck disable=SC2039

#=======================
# OS_USER_ADD_GROUP
#
# Add a given user to a group
#
# Parameters:
#   $1: user name
#   $2: group name
#
# Returns:
#   Non-zero on error.
#
#=======================
OS_USER_ADD_GROUP ()
{
    SPACE_SIGNATURE="targetuser group"
    SPACE_ENV="SUDO=\${SUDO-}"

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
# Message of the day is the greeting text that shows when you login.
#
# Parameters;
#   $1: The path of the motd file to upload.
#
#=======================
OS_MOTD ()
{
    SPACE_SIGNATURE="motdfile"
    # shellcheck disable=2034
    SPACE_REDIR="<${1}"
    SPACE_DEP="FILE_PIPE_WRITE PRINT"

    # shellcheck disable=SC2039
    local motdfile="${1}"
    shift

    PRINT "Replace /etc/motd with ${motdfile}." "debug"

    FILE_PIPE_WRITE "/etc/motd"
}


# Disable warning about indirectly checking status code
# shellcheck disable=SC2181

#=======================
# OS_DISABLE_ROOT
#
# Disable root from logging in both via ssh and physically.
#
# Expects:
#   $SUDO: if not run as root set `SUDO=sudo`
#
# Returns:
#   0: success
#   1: failure
#
#=======================
OS_DISABLE_ROOT ()
{
    SPACE_DEP="PRINT FILE_SED FILE_ROW_PERSIST OS_SERVICE"
    SPACE_ENV="SUDO=\${SUDO-}"

    PRINT "Inactivating root account." "info"

    if [ "$(id -u)" -eq 0 ]; then
        PRINT "Do not run this as root." "error"
        return 1
    fi

    # shellcheck disable=SC2039
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


# Disable warning about indirectly checking status code
# shellcheck disable=SC2181
# Disable warning about local keyword
# shellcheck disable=SC2039

#=======================
# OS_DISABLE_USER
#
# Disable a user from logging in both via ssh and physically.
#
# Parameters:
#   $1: The name of the user to make inactive.
#
# Expects:
#   $SUDO: if not run as root set `SUDO=sudo`
#
# Returns:
#   0: success
#   1: failure
#
#=======================
OS_DISABLE_USER ()
{
    SPACE_SIGNATURE="targetuser"
    SPACE_DEP="PRINT FILE_ROW_PERSIST OS_SERVICE"
    SPACE_ENV="SUDO=\${SUDO-}"

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


# Disable warning about local keyword
# shellcheck disable=SC2039

#============
# OS_SHELL
#
# Enter userland shell.
#
# Parameters:
#   $1: shell name (optional)
#
# Expects:
#   $SUDO: if not run as root set `SUDO=sudo`
#
#============
OS_SHELL ()
{
    # shellcheck disable=2034
    SPACE_SIGNATURE="[shell]"
    # shellcheck disable=2034
    SPACE_DEP="PRINT"
    # shellcheck disable=2034
    SPACE_ENV="SUDO=\${SUDO-}"

    local shell="${1:-sh}"
    shift $(( $# > 0 ? 1 : 0 ))

    PRINT "Enter shell: ${shell}." "debug"

    local SUDO="${SUDO-}"
    # shellcheck disable=2086
    ${SUDO} ${shell}
}


OS_HARDEN()
{
    # shellcheck disable=2034
    SPACE_DEP="PRINT"
    PRINT "Pending implementation..." "warning"
    return 0
}

