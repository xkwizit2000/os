---
modulename: OS
title: /service/
giturl: gitlab.com/space-sh/os
editurl: /edit/master/doc/service.md
weight: 200
---
# OS module: Service

Controls a given service.


## Example

Send `status` action for service named `httpd`:
```sh
space -m os /service/ -- "httpd" "status"
```

Exit status code is expected to be 0 on success.
