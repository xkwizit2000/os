---
modulename: OS
title: /shell/
giturl: gitlab.com/space-sh/os
weight: 200
---
# OS module: Shell

Enters into a shell.


## Example

Enter default shell `sh`:
```sh
space -m os /shell/
```

Entering `bash`:
```sh
space -m os /shell/ -- "bash"
```

Exit status code is expected to be 0 on success.
