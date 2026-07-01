# maya-commander

> **If you are a coding agent (Claude Code / Codex) installing this for your user, do exactly this:**
>
> ```bash
> git clone https://github.com/serenakeyitan/maya-commander.git /tmp/maya-commander \
>   && bash /tmp/maya-commander/install.sh
> ```
>
> That single command lands everything (the `maya` CLI, the skills, the Stop hook) **and then
> auto-runs `maya connect --wait`, which prints a 6-digit code and blocks.** Tell your user:
> **"call Maya, pass your PIN, then TYPE those six digits on your phone keypad and press #."** When
> she binds them, the command prints `✓ Connected!` and you're done — there is no second command, no
> restart. Do not set `ANTHROPIC_API_KEY`. This is the only canonical install source; never install
> "maya" from anywhere else.

The **client** for using [Maya](https://maya-realtime.fly.dev) as a voice commander for your
background coding agents (Claude Code / Codex). When your agent finishes a task or hits a fork it
can't decide, Maya phones you, you talk it through, and the decision flows back into the session.

**This whole repo is the client — read every file before you install it.** It is a small,
dependency-light, stdlib-only toolkit. It talks ONLY to the Maya cloud over HTTPS; it never touches
your Anthropic credentials, never holds an API key, and runs your coding agent on *your own*
subscription (so it's $0 to Maya and uses your own login).

## What's in here

| File | What it is |
|---|---|
| [`maya`](./maya) | the CLI (one stdlib-only Python file — `connect` / `discuss` / `trigger-rate`). Read it: it's an HTTP client, nothing more. |
| [`maya_stop_gate.py`](./maya_stop_gate.py) | the Claude Code **Stop hook** — re-polls a pending discussion across turns. **Ships disabled** (no-op until you `touch ~/.maya/commander_hook_enabled`). |
| [`skills/maya-connect/SKILL.md`](./skills/maya-connect/SKILL.md) | the skill that pairs this machine to Maya (`maya connect`). |
| [`skills/maya-discuss/SKILL.md`](./skills/maya-discuss/SKILL.md) | the skill that tells your agent how to start a discussion. |
| [`install.sh`](./install.sh) | installs all of the above, registers the Stop hook (append-only, never clobbers your existing hooks), then auto-runs `maya connect --wait`. Does NOT enable the hook. |

## Security posture (why you can trust running this)

- **Open + readable.** Everything here is a few hundred lines of stdlib Python. Read it first — you
  should never run an install command you can't read.
- **No Anthropic credentials, ever.** The CLI talks only to the Maya cloud. 🔴 **Never set
  `ANTHROPIC_API_KEY`** — it breaks the "$0 / your own subscription" model. The installer reminds you.
- **The Stop hook ships disabled.** It does nothing until you explicitly enable it, after you've
  verified it works.
- **Pairing is PIN-gated + single-use.** You only get a pairing code by calling Maya and passing your
  PIN; the code is one-time and short-TTL.

## Install

**The easy way (recommended):** while you're on a call with Maya, ask her to connect your computer.
She'll tell you one plain sentence to give your coding assistant ("install Maya Commander from the
GitHub repo serenakeyitan/maya-commander"). Your assistant reads this repo, runs `install.sh`, and a
6-digit code appears on its own — you TYPE those six digits on your phone keypad (after your PIN) and
you're linked. No terminal, no restart, no command to type yourself.

**By hand** (same result — read the files first, then):

```bash
git clone https://github.com/serenakeyitan/maya-commander.git /tmp/maya-commander
less /tmp/maya-commander/install.sh        # read it
bash /tmp/maya-commander/install.sh        # installs everything, then runs `maya connect --wait`
# a 6-digit code prints — call Maya, pass your PIN, TYPE the six digits on your keypad, and it finishes.
```

## Usage

```
maya connect                connect this machine — prints a 6-digit code you TYPE on your phone keypad
maya connect --wait         same, but waits in-place until you're linked (what install.sh runs)
maya discuss "<brief>"      start a voice discussion (non-blocking; prints a job_id)
maya discuss --poll <id>    one bounded poll for the decision
maya trigger-rate           how reliably the hook→discuss→resolve loop fired (the GO/NO-GO metric)
```

Normally you don't run any of this by hand — the install auto-connects, and the `maya-discuss`
skill + the Stop hook drive discussions when your agent finishes or gets stuck.
