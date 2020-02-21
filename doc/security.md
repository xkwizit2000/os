---
modulename: OS
title: /security/
giturl: gitlab.com/space-sh/os
editurl: /edit/master/doc/security.md
weight: 200
---
# OS module: Update limits configuration

Update _/etc/security/limits.conf_ file according to parameters.


## Example

```sh
space -m os /security/ -- "*" "hard" "nofile" "512"
```

Exit status code is expected to be 0 on success.
