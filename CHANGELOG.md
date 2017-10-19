# Space Module change log - os

## [1.3.0 - 2017-10-19]

+ Add `ADD_GROUP` function

+ Add `creategroup` node

+ Add a check against target user in  `CREATE_USER` function


## [1.2.0 - 2017-09-24]

+ Add `/security/limits/set/`

+ Add a check for busybox shell

* Expand `OS_SHELL` to gracefully kill processes when running as `su`

* Update in-code comments

- Disable false positive static analysis warnings


## [1.1.2 - 2017-08-28]

* Fix a bug in grep regular expression for `group_exist` operation

* Rename signature variable in `user_exist` operation

- Disable static analysis warning about unused variables

- Disable static analysis warning about indirectly checking status code


## [1.1.1 - 2017-06-11]

* Update documentation

* Change Arch Linux image for CI tests


## [1.1.0 - 2017-05-19]

+ Add `OS_KILL_ALL`

* Rename expected local OUT variables

- Remove old `SUDO` behavior


## [1.0.1 - 2017-04-26]

* Update auto completion

* Change `SPACE_SIGNATURE` to consider parameter constraints

* Update node descriptions

* Update include and clone statements


## [1.0.0 - 2017-04-12]

+ Initial version
