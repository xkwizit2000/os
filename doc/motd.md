---
modulename: OS
title: /motd/
giturl: gitlab.com/space-sh/os
editurl: /edit/master/doc/motd.md
weight: 200
---
# OS module: Message of the day

Create or replace an existing _Message of the Day_ (motd) file.


## Example

```sh
space -m os /motd/ -- "/tmp/message-from-janitor.txt"
```

Exit status code is expected to be 0 on success.
