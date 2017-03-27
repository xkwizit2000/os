---
modulename: OS
title: /install/
giturl: gitlab.com/space-sh/os
weight: 200
---
# OS module: Install

Installs a given package, following _Debian-style_ naming convention.


## Example

```sh
space -m os /install/ -- "vim"
```

Exit status code is expected to be 0 on success.
