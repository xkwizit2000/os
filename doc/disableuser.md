---
modulename: OS
title: /disableuser/
giturl: gitlab.com/space-sh/os
weight: 200
---
# OS module: Disable user

Disable a given user account, preventing it from being used for logging in.


## Example

```sh
space -m os /disableuser/ -- "janitor"
```

Exit status code is expected to be 0 on success.
