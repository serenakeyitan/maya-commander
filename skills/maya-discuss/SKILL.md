---
name: maya-discuss
description: >-
  Phone the owner and talk through a decision when a background coding task is finished or stuck at
  a fork in the road. Use this when you've completed a chunk of work and need the owner's direction,
  when you hit a branch you can't resolve on your own (e.g. "merge this or keep splitting?", "delete
  the schema or keep it?"), or when the owner asked to be called to decide. Also runs as the manual
  /maya-discuss command. It sends a short brief to Maya, who calls the owner; the owner discusses it
  by voice and the agreed instruction comes back as the authoritative next step.
disable-model-invocation: false
allowed-tools: Bash(maya discuss *), Bash(maya pair *)
---

# maya-discuss — voice-discuss a decision with the owner

You are about to hand a decision to the owner over a phone call with Maya (their voice companion),
then continue based on what they decide. Do this in three steps.

## 1. Write a thick brief (2–4 sentences)

Distill the situation so Maya can open the call already understanding it. Include:
- **What you just did / where you are.**
- **The fork** — the specific options or the thing you're stuck on.
- **Your initial lean**, if you have one, and why.
- **The question** you want the owner to answer.

This brief is the ONLY thing that leaves this machine — keep it a distilled summary, never paste raw
code, file contents, secrets, or transcripts. It is byte-capped server-side regardless.

## 2. Run the CLI and don't block forever

Run this with the **Bash tool** (not the `!command` injection syntax — that pre-executes at load time):

```
maya discuss "<your thick brief>"
```

It returns immediately with a `job_id` (it does NOT block for the whole call — that's deliberate, to
survive the 10-minute Bash cap). Maya then phones the owner.

To get the decision, poll once:

```
maya discuss --poll <job_id>
```

This waits up to ~60 seconds, then prints either the owner's **instruction** (follow it) or a
`PENDING` line (the discussion is still going). On PENDING it's fine to stop — the Stop hook re-polls
on the next turn until it resolves.

## 3. Treat the returned instruction as authoritative

When `--poll` prints an instruction, that IS the owner's decision — follow it as the next step. If it
prints `COMMANDER_NO_ANSWER` / `COMMANDER_EXPIRED` (Maya couldn't reach them), proceed using your own
best judgment and say so.

## Setup (once)

This needs the `maya` CLI installed and this machine paired (`maya pair <code>`). If `maya discuss`
says the machine isn't paired, tell the owner to call Maya for a pairing code and run `maya pair`.
Never set `ANTHROPIC_API_KEY` in this environment — it breaks the $0/subscription model.
