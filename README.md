# OS module | [![build status](https://gitlab.com/space-sh/os/badges/master/build.svg)](https://gitlab.com/space-sh/os/commits/master)

Handle operating system tasks such as user management, packages and services management.



## /createuser/
	Create a new user


## /disableroot/
	Disable root login

	Run this to make it so that the root user no longer can login
	over SSH. This increases the security of the machine.
	Note: make sure the super user has been setup successfully first.
	


## /disableuser/
	Disable an user account

	Disable a user from logging in.
	


## /groupexist/
	Check if a group exists


## /harden/
	Harden the machine


## /info/
	Show information about the OS


## /install/
	Install any pkg

	Pkg name as positional argument.
	Always provide Debian names.
	


## /installsudo/
	Install the 'sudo' pkg


## /mksudo/
	Make an existing user into sudo


## /motd/
	Create/replace motd file


## /reboot/
	Reboot the system


## /service/
	Control a service


## /shell/
	Enter into shell


## /update/
	Update the OS package lists


## /upgrade/
	Update and upgrade OS


## /userexist/
	Check if a user exists


# Functions 

## OS\_DEP\_INSTALL()  
  
  
  
Check for dependencies  
  
  
  
## OS\_ID()  
  
  
  
Get the OS identification and package manager.  
  
### Expects:  
- out\_ostype  
- out\_ospkgmgr  
- out\_oshome - Users home dir.  
- out\_oscwd - Current CWD.  
  
  
  
## OS\_INFO()  
  
  
  
Show some information about the current OS.  
  
  
  
## OS\_IS\_INSTALLED()  
  
  
  
Check if program is installed.  
If not installed then install its package, if provided.  
  
### Parameters:  
- $1: program name  
- $2: package name  
  
### Returns:  
- 0: program is available  
- 0: program is not available and failed to install it  
  
  
  
## \_OS\_PKG\_TRANSLATE()  
  
  
  
Translates Debian style package names into  
the current OS package manager naming.  
  
A translation could be translated into one or many  
package names.  
  
### Expects:  
- ${pkg}: package(s) name(s) to adjust  
  
  
  
## \_OS\_PROGRAM\_TRANSLATE()  
  
  
  
Translates Debian style program names into  
the current OS distributions program naming.  
  
### Expects:  
- ${program}: program name to translate  
  
  
  
## OS\_INSTALL\_PKG()  
  
  
  
Install one or more packages.  
  
Give the Debian style name of packages  
and the function will attempt to translate  
it to the current package managers name for it.  
  
### Parameters:  
- $1: package(s) name(s)  
  
### Returns:  
- 0: success  
- 1: failed to install package either due to unknown package manager or package name  
  
  
  
## OS\_UPDATE()  
  
  
  
Update the system package lists.  
  
  
  
## OS\_UPGRADE()  
  
  
  
Upgrade the system.  
  
### Returns:  
- Non-zero on error.  
  
  
  
## OS\_SERVICE()  
  
  
  
Control a service.  
  
### Parameters:  
- $1: service name  
- $2: action  
  
### Returns:  
- 0: success  
- 1: failure  
  
  
  
## OS\_REBOOT()  
  
  
  
Reboot the system.  
  
  
  
## OS\_USER\_EXIST()  
  
  
  
Check if a user does exist.  
  
### Parameters:  
- $1: the name of the user to lookup.  
  
### Returns:  
- 0: users does exist  
- 1: failure. User does NOT exist  
  
  
  
## OS\_GROUP\_EXIST()  
  
  
  
Check if a group does exist.  
  
### Parameters:  
- $1: the name of the group to lookup.  
  
### Returns:  
- 0: group does exist  
- 1: failure. Group does NOT exist  
  
  
  
## OS\_CREATE\_USER()  
  
  
  
Create passwordless user and install ssh key for it.  
  
### Parameters:  
- $1: The name of the user to create.  
- $2: Path of the pub key file to install for the user.  
  
### Returns:  
- 0: success  
- 1: failure  
  
  
  
## OS\_ADD\_USER()  
  
  
  
Add a user, with a home directory.  
  
### Parameters:  
- $1: user name  
- $2: home path directory  
- $3: shell path  
  
### Returns:  
- 0: success  
- 1: failed to call useradd/adduser  
  
  
  
## OS\_COMMAND()  
  
  
  
### Parameters:  
- $1: command to look for  
  
- Return:  
- Same as 'command'  
  
  
  
## OS\_MKSUDO\_USER()  
  
  
  
Make a user passwordless SUDO.  
  
### Parameters:  
- $1: The name of the user to make into sudo user.  
  
### Returns:  
- 0: success  
- 1: failure  
  
  
  
## OS\_USER\_ADD\_GROUP()  
  
  
  
Add a given user to a group  
  
### Parameters:  
- $1: user name  
- $2: group name  
  
### Returns:  
- Non-zero on error.  
  
  
  
## OS\_MOTD()  
  
  
  
Copy a motd file into the system.  
Message of the day is the greeting text that shows when you login.  
  
Parameters;  
$1: The path of the motd file to upload.  
  
  
  
## OS\_DISABLE\_ROOT()  
  
  
  
Disable root from logging in both via ssh and physically.  
  
### Returns:  
- 0: success  
- 1: failure  
  
  
  
## OS\_DISABLE\_USER()  
  
  
  
Disable a user from logging in both via ssh and physically.  
  
### Parameters:  
- $1: The name of the user to make inactive.  
  
### Returns:  
- 0: success  
- 1: failure  
  
  
  
## OS\_SHELL()  
  
  
  
Enter userland shell.  
  
### Parameters:  
- $1: shell name (optional).  
- $@: optional commands to run in shell.  
  
  
  
