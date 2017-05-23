---
modulename: OS
title: /createuser/
giturl: gitlab.com/space-sh/os
editurl: /edit/master/doc/createuser.md
weight: 200
---
# OS module: Create user

Creates a new user.


## Example

Creates a new regular user:
```sh
space -m os /createuser/ -- "janitor"
```

Creates a new user providing a _ssh_ public key:
```sh
space -m os /createuser/ -- "janitor" "/tmp/janitor.pub"
```


Exit status code is expected to be 0 on success.
