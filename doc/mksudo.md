---
modulename: OS
title: /mksudo/
giturl: gitlab.com/space-sh/os
editurl: /edit/master/doc/mksudo.md
weight: 200
---
# OS module: Make sudo

Make an existing user into `sudo`.


## Example

```sh
space -m os /makesudo/ -- "janitor"
```

Exit status code is expected to be 0 on success.
