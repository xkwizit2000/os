---
modulename: OS
title: /disableroot/
giturl: gitlab.com/space-sh/os
weight: 200
---
# OS module: Disable root

Disable `root` login. This makes it impossible to login as `root` both via _SSH_ and physically.


## Example

```sh
space -m os /disableroot/
```

Exit status code is expected to be 0 on success.
