---
name: maya-on
description: >-
  Turn ON Maya's auto-call (the Stop hook) so Maya calls the user automatically when a background
  coding agent finishes or gets stuck on a decision. Requires the machine to already be paired
  (`maya connect`). Use when the user says "maya on", "turn on maya", "enable auto-call",
  "let maya call me", "开启 maya", "打开自动呼叫", or runs the /maya-on command.
disable-model-invocation: false
allowed-tools: Bash(maya on), Bash(maya status)
---

# maya-on — let Maya call automatically when an agent needs a decision

Turn ON auto-call. From now on, when a background coding agent finishes a task or hits a fork it
can't decide, Maya phones the user; they decide by voice and the decision flows back into the session.

## Do this

Run with the Bash tool and show the output:

```
maya on
```

It creates the auto-call flag (idempotent). If it says **not connected**, the machine isn't paired
yet — have the user run `maya connect` first (auto-call needs a real token to place the call).

Confirm to the user: **auto-call is on; turn it off anytime with `maya off` (which keeps the
connection).** If they want to check state, run `maya status`.
