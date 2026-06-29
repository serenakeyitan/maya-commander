---
name: maya-connect
description: >-
  Connect this computer to Maya (the user's voice companion) so Maya can phone the user for a
  decision when a background coding task finishes or gets stuck. Use when the user says "connect this
  to Maya", "connect my Claude Code to Maya", "link Maya to my computer", "set up Maya commander",
  "pair this machine with Maya", or "connect me to Maya". One-time setup: shows a 6-digit code the
  user reads to Maya on a phone call, then links this machine.
disable-model-invocation: false
allowed-tools: Bash(maya connect *)
---

# maya-connect — link this computer to Maya

Connect this machine to the user's Maya account so Maya can call them about this agent's work. It's a
one-time setup and takes about a minute.

## Steps

1. **Start it** — run with the Bash tool and show the user the output:

   ```
   maya connect
   ```

   It prints a **6-digit code** and the number to call. Read the user the code and tell them:
   *"Call Maya at that number, and when she asks, read her these six digits."*

2. **Wait for them to call + read the code.** While they do, poll once:

   ```
   maya connect --poll
   ```

   This waits up to ~90 seconds. If it prints `Connected!`, you're done — tell the user their
   computer is now linked. If it prints `PENDING`, they haven't read the code to Maya yet — that's
   fine, run `maya connect --poll` again on the next turn until it connects.

3. **Done.** Once connected, the user can ask Maya to call them about your work, and (optionally)
   Maya can auto-call when you finish or get stuck.

## Notes

- The 6-digit code is shown on THIS screen and read aloud to Maya — it never travels by text. It
  expires in a few minutes; if it lapses, just run `maya connect` again for a fresh one.
- This needs the `maya` CLI installed (it is, if this skill exists). Never set `ANTHROPIC_API_KEY` —
  it must stay on the user's own subscription.
- If the user hasn't set up a Maya account / PIN yet, they do that by calling Maya first; pairing
  reuses that same verified phone identity.
