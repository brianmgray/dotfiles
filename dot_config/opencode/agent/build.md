---
mode: subagent
permission:
  edit: allow
  bash:
    "*": allow
    "rm -rf*": deny
    "sudo*": deny
  write: allow
---