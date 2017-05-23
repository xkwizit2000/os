---
modulename: OS
title: /userexist/
giturl: gitlab.com/space-sh/os
editurl: /edit/master/doc/userexist.md
weight: 200
---
# OS module: User exist

Check if a given user name exists.


## Example

```sh
space -m os /userexist/ -- "root"
```

Exit status code is expected to be 0 on success.
