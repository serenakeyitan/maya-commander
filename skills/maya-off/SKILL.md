---
name: maya-off
description: >-
  Turn OFF Maya's auto-call (the Stop hook) so Maya stops calling automatically when a background
  coding agent finishes or gets stuck. KEEPS the connection — the machine stays paired and manual
  `maya discuss` still works; this only silences the automatic calls. Use when the user says
  "maya off", "turn off maya", "stop maya calling me", "disable auto-call", "mute maya",
  "关掉 maya", "停止自动呼叫", or runs the /maya-off command.
disable-model-invocation: false
allowed-tools: Bash(maya off), Bash(maya status)
---

# maya-off — silence Maya's automatic calls (keep the connection)

Turn OFF auto-call. Maya will no longer phone the user automatically when a background agent finishes
or hits a fork. **The connection is untouched** — the machine stays paired, and the user can still run
`maya discuss "<question>"` manually to be called.

## Do this

Run with the Bash tool and show the output:

```
maya off
```

That's it — it removes the auto-call flag (idempotent; fine if it was already off). Confirm to the
user: **auto-call is off, they're still connected, and `maya on` re-enables it anytime.**

If they want to see the current state instead, run `maya status`.
