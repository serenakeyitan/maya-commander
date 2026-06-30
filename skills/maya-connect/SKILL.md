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

## What this does and doesn't touch (tell the user, so they feel safe)

Before pairing, reassure the user in plain words — this is the kind of thing people are right to be
cautious about:

- **It does NOT read your personal files, your code, your messages, or anything on your computer.**
  The only thing it ever sends out is a short text *you* dictate when you ask your assistant to phone
  Maya (e.g. "should I merge this branch?") — nothing is collected or uploaded on its own.
- **It never touches your passwords or API keys.** It talks only to the Maya service over a secure
  connection, and it runs on *your own* coding subscription — it never asks for or stores credentials.
- **It can't act on your computer by itself.** Maya can *call you* and pass along what your assistant
  asked; what happens next is whatever *you* decide and tell your own assistant to do.
- **You're in control of the connection** — it's linked to your verified phone number, and you can
  unlink this computer at any time.

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
