#
# Copyright 2016-2017 Blockie AB
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

#================================
# OS_DEP_INSTALL
#
# Check for dependencies
#
#================================
OS_DEP_INSTALL()
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
#   out_ostype
#   out_ospkgmgr
#   out_oshome - Users home dir.
#   out_oscwd - Current CWD.
#
#================
OS_ID()
{
    SPACE_DEP="OS_COMMAND"

    out_ostype="gnu"
    out_oshome="/home"
    out_oscwd="$(pwd)"
    out_ospkgmgr=
    out_osinit="sysvinit"

    if OS_COMMAND "systemctl" >/dev/null; then
        out_osinit="systemd"
    fi

    if [ "${out_oscwd}" = "/" ]; then
        # We'll conform the root directory to not end with slash,
        # since other directories do not end with slash.
        out_oscwd="/."
    fi

    [ -f "/etc/debian_version" ] && out_ospkgmgr="apt"
    [ -f "/etc/arch-release" ] && out_ospkgmgr="pacman"
    [ -d "/etc/yum" ] && out_ospkgmgr="yum"
    [ -f "/etc/redhat-release" ] && out_ospkgmgr="yum"
    [ -f "/etc/alpine-release" ] && { out_ospkgmgr="apk"; out_ostype="busybox"; }

    # Some releases are more tricky.
    if [ "${out_ospkgmgr}" = "" ]; then
        if OS_COMMAND "apt-get" >/dev/null; then
            out_ospkgmgr="apt"
        elif OS_COMMAND "pacman" >/dev/null; then
            out_ospkgmgr="pacman"
        elif OS_COMMAND "yum" >/dev/null; then
            out_ospkgmgr="yum"
        elif OS_COMMAND "apk" >/dev/null; then
            out_ospkgmgr="apk"
            # We assume Alpine Linux runs on BusyBox.
            # We could have a more fine grained check,
            # but we would have to execute 'ls' a couple of times to do that.
            out_ostype="busybox"
        elif OS_COMMAND "brew" >/dev/null; then
            out_ospkgmgr="brew"
            out_ostype="darwin"
            out_oshome="/Users"
            out_osinit="launchd"
        elif OS_COMMAND "pkg" >/dev/null; then
            out_ospkgmgr="pkg"
            out_ostype="FreeBSD"
            out_osinit="rc"
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
OS_INFO()
{
    SPACE_DEP="OS_ID PRINT"

    local out_ostype=''
    local out_ospkgmgr=''
    local out_oshome=''
    local out_oscwd=''
    local out_osinit=''
    OS_ID

    PRINT "OS type: ${out_ostype}."
    PRINT "OS init system: ${out_osinit}."
    PRINT "OS package manager: ${out_ospkgmgr}."
    PRINT "OS home directory: ${out_oshome}."
    PRINT "Current directory: ${out_oscwd}."
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
OS_IS_INSTALLED()
{
    SPACE_SIGNATURE="program:1 [pkg]"
    SPACE_DEP="OS_INSTALL_PKG _OS_PROGRAM_TRANSLATE PRINT OS_COMMAND"

    local program="${1}"
    shift

    local pkg="${1-}"
    shift $(( $# > 0 ? 1 : 0 ))

    local program2="${program}"

    local out_ostype=''
    local out_ospkgmgr=''
    local out_oshome=''
    local out_oscwd=''
    local out_osinit=''
    OS_ID

    _OS_PROGRAM_TRANSLATE

    PRINT "Check if ${program} (originally ${program2}) is installed." "debug"
    if OS_COMMAND "${program}" >/dev/null; then
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
_OS_PKG_TRANSLATE()
{
    local out_ostype=''
    local out_ospkgmgr=''
    local out_oshome=''
    local out_oscwd=''
    local out_osinit=''
    OS_ID

    local pkg2="${pkg}"
    local p=""
    pkg=""
    for p in ${pkg2}; do
        # This function should be further added to
        # to handle more packages.
        if [ "${out_ospkgmgr}" = "apk" ]; then
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
        elif [ "${out_ospkgmgr}" = "yum" ]; then
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
        elif [ "${out_ospkgmgr}" = "pacman" ]; then
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
_OS_PROGRAM_TRANSLATE()
{
    local out_ostype=''
    local out_ospkgmgr=''
    local out_oshome=''
    local out_oscwd=''
    local out_osinit=''
    OS_ID

    # This function should be further added to
    # to handle more programs.
    if [ "${out_ospkgmgr}" = "apk" ]; then
        :
    elif [ "${out_ospkgmgr}" = "yum" ]; then
        if [ "${program}" = "lua5.1" ]; then
            program="lua"
        fi
    elif [ "${out_ospkgmgr}" = "pacman" ]; then
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
OS_INSTALL_PKG()
{
    SPACE_SIGNATURE="pkg:1"
    SPACE_DEP="OS_ID _OS_PKG_TRANSLATE OS_UPDATE PRINT"

    local pkg="${1}"
    shift

    PRINT "Install pkg(s) (untranslated): ${pkg}." "debug"

    local out_ostype=''
    local out_ospkgmgr=''
    local out_oshome=''
    local out_oscwd=''
    local out_osinit=''
    OS_ID

    _OS_PKG_TRANSLATE

    if [ "${pkg}" = "" ]; then
        PRINT "Package has no target for pkg mgr: ${out_ospkgmgr}."
        return 0
    fi

    PRINT "Install package(s) using ${out_ospkgmgr}: ${pkg}." "info"

    if [ "${out_ospkgmgr}" = "apt" ]; then
        apt-get -y install ${pkg}
        if [ "$?" -eq 100 ]; then
            OS_UPDATE
            apt-get -y install ${pkg}
        fi
    elif [ "${out_ospkgmgr}" = "pacman" ]; then
        pacman -Syu --noconfirm ${pkg}
        if [ "$?" -gt 0 ]; then
            OS_UPDATE
            pacman -Syu --noconfirm ${pkg}
        fi
    elif [ "${out_ospkgmgr}" = "yum" ]; then
        yum -y install ${pkg}
    elif [ "${out_ospkgmgr}" = "apk" ]; then
        apk add ${pkg}
        if [ "$?" -gt 0 ]; then
            OS_UPDATE
            apk add ${pkg}
        fi
    elif [ "${out_ospkgmgr}" = "brew" ]; then
        brew install ${pkg}
        if [ "$?" -gt 0 ]; then
            OS_UPDATE
            brew install ${pkg}
        fi
    elif [ "${out_ospkgmgr}" = "pkg" ]; then
        pkg install ${pkg}
        if [ "$?" -gt 0 ]; then
            OS_UPDATE
            pkg install ${pkg}
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
#=======================
OS_UPDATE()
{
    SPACE_DEP="OS_ID PRINT"

    local out_ostype=''
    local out_ospkgmgr=''
    local out_oshome=''
    local out_oscwd=''
    local out_osinit=''
    OS_ID

    PRINT "Update package lists." "info"

    if [ "${out_ospkgmgr}" = "apt" ]; then
        apt-get update -y
    elif [ "${out_ospkgmgr}" = "pacman" ]; then
        pacman --noconfirm -Sy
    elif [ "${out_ospkgmgr}" = "yum" ]; then
        :
    elif [ "${out_ospkgmgr}" = "apk" ]; then
        apk update
    elif [ "${out_ospkgmgr}" = "brew" ]; then
        brew update
    elif [ "${out_ospkgmgr}" = "pkg" ]; then
        pkg update
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
# Returns:
#   Non-zero on error.
#
#=======================
OS_UPGRADE()
{
    SPACE_DEP="OS_ID OS_UPDATE PRINT"

    OS_UPDATE
    if [ "$?" -gt 0 ]; then
        return 1
    fi

    local out_ostype=''
    local out_ospkgmgr=''
    local out_oshome=''
    local out_oscwd=''
    local out_osinit=''
    OS_ID

    PRINT "Upgrade OS..." "info"

    if [ "${out_ospkgmgr}" = "apt" ]; then
        apt-get -y upgrade
    elif [ "${out_ospkgmgr}" = "pacman" ]; then
        pacman --noconfirm -Syu
    elif [ "${out_ospkgmgr}" = "yum" ]; then
        yum update -y
    elif [ "${out_ospkgmgr}" = "apk" ]; then
        apk upgrade
    elif [ "${out_ospkgmgr}" = "brew" ]; then
        brew upgrade
    elif [ "${out_ospkgmgr}" = "pkg" ]; then
        pkg upgrade
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
# Returns:
#   0: success
#   1: failure
#
#=======================
OS_SERVICE()
{
    SPACE_SIGNATURE="service:1 action:1"
    SPACE_DEP="PRINT OS_ID"

    local service="${1}"
    shift

    local action="${1}"
    shift

    PRINT "Service ${service}, ${action}." "info"

    local out_ostype=''
    local out_ospkgmgr=''
    local out_oshome=''
    local out_oscwd=''
    local out_osinit=''
    OS_ID

    if [ "${out_osinit}" = "systemd" ]; then
        systemctl "${action}" "${service}"
    elif [ "${out_osinit}" = "sysvinit" ]; then
        "/etc/init.d/${service}" "${action}"
    elif [ "${out_osinit}" = "launchd" ]; then
        launchctl "${action}" "${service}"
    elif [ "${out_osinit}" = "rc" ]; then
        "/etc/rc.d/${service}" "${action}"
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
#=======================
OS_REBOOT()
{
    SPACE_DEP="PRINT OS_ID"

    PRINT "Reboot system now." "info"

    local out_ostype=''
    local out_ospkgmgr=''
    local out_oshome=''
    local out_oscwd=''
    local out_osinit=''
    OS_ID

    if [ "${out_osinit}" = "systemd" ]; then
        systemctl reboot
    elif [ "${out_osinit}" = "sysvinit" ] \
      || [ "${out_osinit}" = "launchd" ]  \
      || [ "${out_osinit}" = "rc" ]; then
        reboot now
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
OS_USER_EXIST()
{
    SPACE_SIGNATURE="user:1"
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
OS_GROUP_EXIST()
{
    SPACE_SIGNATURE="group:1"
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
# Returns:
#   0: success
#   1: failure
#
#=======================
OS_CREATE_USER()
{
    SPACE_SIGNATURE="targetuser:1 sshpubkeyfile:1"
    SPACE_REDIR="<${2}"
    SPACE_DEP="PRINT FILE_CHMOD FILE_MKDIRP FILE_PIPE_WRITE FILE_CHOWNR OS_ID OS_ADD_USER"

    local targetuser="${1}"
    shift

    # This is used on SPACE_REDIR.
    # shellcheck disable=2034
    local sshpubkeyfile="${1}"
    shift

    PRINT "Create ${targetuser}." "debug"

    # shellcheck disable=2034
    local out_ostype=''
    local out_ospkgmgr=''
    local out_oshome=''
    local out_oscwd=''
    local out_osinit=''
    OS_ID

    local home="${out_oshome}/${targetuser}"
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
OS_ADD_USER()
{
    SPACE_SIGNATURE="user:1 home:1 [shell]"
    SPACE_DEP="OS_COMMAND"

    local targetuser="${1}"
    shift

    local home="${1}"
    shift

    local shpath="${1-}"
    shift $(( $# > 0 ? 1 : 0 ))

    if [ "${shpath}" = "" ]; then
        shpath="$(OS_COMMAND bash)"
        if [ "$?" -gt 0 ]; then
            shpath="$(OS_COMMAND sh)"
        fi
    fi

    if OS_COMMAND useradd >/dev/null; then
        useradd -m -d "${home}" -s "${shpath}" -U "${targetuser}"
    elif OS_COMMAND adduser >/dev/null; then
        adduser -D -h "${home}" -s "${shpath}" "${targetuser}"
    else
        PRINT "No useradd/adduser installed." "error"
        return 1
    fi
}


# Disable warning about local keyword
# shellcheck disable=SC2039

#===========
# OS_COMMAND
#
# Parameters:
#   $1: command to look for
#
# Return:
#   Same as 'command'
#
#===========
OS_COMMAND()
{
    SPACE_SIGNATURE="command:1"

    local cmd="${1}"
    shift

    command -v ${cmd} >/dev/null
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
# Returns:
#   0: success
#   1: failure
#
#=======================
OS_MKSUDO_USER()
{
    SPACE_SIGNATURE="targetuser:1"
    SPACE_DEP="PRINT FILE_ROW_PERSIST OS_USER_ADD_GROUP OS_GROUP_EXIST"

    local targetuser="${1}"
    shift

    PRINT "mksudo ${targetuser}." "info"

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
OS_USER_ADD_GROUP()
{
    SPACE_SIGNATURE="targetuser:1 group:1"
    SPACE_DEP="OS_COMMAND PRINT"

    local targetuser="${1}"
    shift

    local group="${1}"
    shift

    if OS_COMMAND usermod >/dev/null; then
        PRINT "User usermod -Ag to add the user: '${targetuser}' to the group: '${group}'" "debug"
        usermod -aG "${group}" "${targetuser}"
    elif OS_COMMAND addgroup >/dev/null; then
        addgroup "${targetuser}" "${group}"
    else
        PRINT "Nor 'usermod' nor 'addgroup' found, can't add user to group." "error"
        return 1
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
OS_MOTD()
{
    SPACE_SIGNATURE="motdfile:1"
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
# Returns:
#   0: success
#   1: failure
#
#=======================
OS_DISABLE_ROOT()
{
    SPACE_DEP="PRINT FILE_SED FILE_ROW_PERSIST OS_SERVICE"

    PRINT "Inactivating root account." "info"

    if [ "$(id -u)" -eq 0 ]; then
        PRINT "Do not run this as root." "error"
        return 1
    fi

    passwd -d root &&
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
# Returns:
#   0: success
#   1: failure
#
#=======================
OS_DISABLE_USER()
{
    SPACE_SIGNATURE="targetuser:1"
    SPACE_DEP="PRINT FILE_ROW_PERSIST OS_SERVICE"

    local targetuser="${1}"
    shift

    if [ "$(whoami)" = "${targetuser}" ]; then
        PRINT "This is you! Sawing of the branch you're sitting on?" "error"
        return 1
    fi

    PRINT "Inactivate user ${targetuser}." "info"

    passwd -d "${targetuser}" &&
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
#   $1: shell name (optional).
#   $@: optional commands to run in shell.
#
#============
OS_SHELL()
{
    # shellcheck disable=2034
    SPACE_SIGNATURE="[shell command]"
    # shellcheck disable=2034
    SPACE_DEP="PRINT STRING_ESCAPE"

    local shell="${1:-sh}"
    shift $(( $# > 0 ? 1 : 0 ))

    local cmd="$@"

    if [ -z "${cmd}" ]; then
        PRINT "Entering shell: ${shell}." "debug"
        # shellcheck disable=2086
        ${shell}
    else
        PRINT "Exec command in shell: ${shell}." "debug"
        # shellcheck disable=2086
        STRING_ESCAPE "cmd" '$'
        ${shell} -c "${cmd}"
    fi
}


OS_HARDEN()
{
    # shellcheck disable=2034
    SPACE_DEP="PRINT"
    PRINT "Pending implementation..." "warning"
    return 0
}

#============
# OS_KILL_ALL
#
# Kill all descendant processes to given PID.
#
# Parameters:
# $1: PID to kill descendants for
# $2: Include PID it self, default 1.
#
# Returns:
#   non-zero on error
#
#============
OS_KILL_ALL()
{
    SPACE_SIGNATURE="PID [inclusive]"

    local toppid="${1}"
    shift

    local inclusive="${1-1}"
    shift $(($# > 0 ? 1 : 0))

    local pids="${toppid}"
    local allpids=""
    local pid=

    while true; do
        local newpids=
        for pid in ${pids}; do
            local pids2=
            pids2=$(ps -ef | awk '$3 == '${pid}' { print $2 }' 2>/dev/null)
            if [ "$?" -gt 0 ]; then
                # Note: Dash will always return with error code here, but still it worked,
                # so we check if $pids2 contains anything instead of relying on error code.
                :
            fi
            if [ -n "${pids2}" ]; then
                newpids="${newpids} ${pids2}"
            fi
        done
        if [ -z "${newpids}" ]; then
            break
        fi
        allpids="${newpids} ${allpids}"
        pids="${newpids}"
    done

    if [ "${inclusive}" = 1 ]; then
        allpids="${allpids} ${toppid}"
    fi

    for pid in ${allpids}; do
        kill -9 "${pid}" 2>/dev/null
    done

    return 0
}
