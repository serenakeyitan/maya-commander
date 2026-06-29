# maya-commander

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
| [`maya`](./maya) | the CLI (one stdlib-only Python file — `pair` / `discuss` / `trigger-rate`). Read it: it's an HTTP client, nothing more. |
| [`maya_stop_gate.py`](./maya_stop_gate.py) | the Claude Code **Stop hook** — re-polls a pending discussion across turns. **Ships disabled** (no-op until you `touch ~/.maya/commander_hook_enabled`). |
| [`skills/maya-discuss/SKILL.md`](./skills/maya-discuss/SKILL.md) | the skill that tells your agent how to start a discussion. |
| [`install.sh`](./install.sh) | installs the three above + registers the Stop hook (append-only, never clobbers your existing hooks). Does NOT enable the hook. |

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

You'll be onboarded **by Maya on a phone call** — she texts you a ready-to-paste prompt for your
coding agent. But if you're doing it by hand:

```bash
# read the files first, then:
curl -fsSL https://raw.githubusercontent.com/serenakeyitan/maya-commander/main/install.sh -o /tmp/maya-install.sh
less /tmp/maya-install.sh        # read it
bash /tmp/maya-install.sh
# restart Claude Code once (new skills dir), then pair:
maya pair <code-Maya-texted-you>
```

## Usage

```
maya connect                connect this machine — shows a 6-digit code you read to Maya on a call (the easy way)
maya pair <code>            [legacy] redeem a long code out-of-band (fallback)
maya discuss "<brief>"      start a voice discussion (non-blocking; prints a job_id)
maya discuss --poll <id>    one bounded poll for the decision
maya trigger-rate           how reliably the hook→discuss→resolve loop fired (the GO/NO-GO metric)
```

Normally you don't run `discuss` by hand — the `maya-discuss` skill + the Stop hook drive it when
your agent finishes or gets stuck.
