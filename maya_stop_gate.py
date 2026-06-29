#!/usr/bin/env python3
"""COMMANDER M3 — the Claude Code Stop hook that re-arms a pending `maya discuss` across turns.

THE 600s-CAP SURVIVAL (the core M3 mechanism): a real phone discussion can exceed Bash's 10-min hard
cap, so `maya discuss` is NON-BLOCKING — it POSTs the job and exits fast, and `maya discuss --poll`
does ONE bounded ~60s poll then exits 0 (resolved → prints the instruction; pending → prints a
sentinel). This Stop hook is what keeps the loop alive ACROSS turns: when the model tries to stop
while a commander job for this session is still open+unresolved, the hook BLOCKS the stop and injects
the literal `maya discuss --poll <job_id>` command, so the next turn re-polls. Once the job resolves
(or none is pending), the hook lets the stop proceed.

WHY KEY OFF PERSISTED JOB STATE, NOT stop_hook_active ALONE: stop_hook_active only tells us the hook
already fired this stop-sequence; it can't tell us whether there's still a discussion to wait on. We
read the per-session pending-job file (~/.maya/pending/<session_id>, written by `maya discuss`) and
block ONLY while a real job is open. That makes the infinite-loop guard precise: no pending job → no
block, ever.

SHIPS DISABLED: the hook is a NO-OP unless ~/.maya/commander_hook_enabled exists. Per the M3 plan the
hook is the one un-flaggable piece, so it stays off until the live trigger rate is measured (the
GO/NO-GO gate). Enable by `touch ~/.maya/commander_hook_enabled` once you've decided to.

CONTRACT (Claude Code hooks): reads a JSON object on stdin with at least {session_id, stop_hook_active}.
To BLOCK a stop and inject text, print {"decision":"block","reason":"<text>"} and exit 0. To allow the
stop, print nothing (or {}) and exit 0. The reason is DECLARATIVE (not imperative) so it doesn't trip
prompt-injection defenses, and it embeds the literal command as a desktop fallback.
"""
from __future__ import annotations

import json
import os
import sys

MAYA_DIR = os.path.expanduser("~/.maya")
PENDING_DIR = os.path.join(MAYA_DIR, "pending")  # one record per session: {job_id, status}
ENABLED_FLAG = os.path.join(MAYA_DIR, "commander_hook_enabled")
SEAM_LOG = os.path.join(MAYA_DIR, "commander.log")  # the M3 trigger-rate funnel (shared with the CLI)


def _log_seam(seam: str, job_id: str = "") -> None:
    """Append one seam line to ~/.maya/commander.log (best-effort; never crashes the hook)."""
    try:
        os.makedirs(MAYA_DIR, mode=0o700, exist_ok=True)
        with open(SEAM_LOG, "a", encoding="utf-8") as fh:
            fh.write(f"seam={seam} job_id={job_id or '-'}\n")
    except OSError:
        pass


def _read_stdin_json() -> dict:
    try:
        raw = sys.stdin.read()
        data = json.loads(raw or "{}")
        return data if isinstance(data, dict) else {}
    except Exception:  # noqa: BLE001 — a malformed payload must never crash the hook (→ allow stop)
        return {}


def _safe_name(session_id: str) -> str:
    """Filesystem-safe filename for a session id (defend against path traversal in the id)."""
    return "".join(c for c in session_id if c.isalnum() or c in "-_")[:128]


def _pending_job_for_session(session_id: str) -> dict | None:
    """The pending commander job record `maya discuss` persisted for this session, or None.

    Shape (written by the CLI): {"job_id": "...", "status": "open"} keyed at ~/.maya/pending/<sid>.
    'open' means discuss POSTed a job and it hasn't resolved yet; the CLI clears it on resolve.
    """
    if not session_id:
        return None
    path = os.path.join(PENDING_DIR, _safe_name(session_id))
    try:
        with open(path, encoding="utf-8") as fh:
            rec = json.load(fh)
        return rec if isinstance(rec, dict) else None
    except (OSError, ValueError):
        return None


def main() -> int:
    # Disabled by default — no flag file → allow the stop, do nothing. (The GO/NO-GO gate.)
    if not os.path.exists(ENABLED_FLAG):
        return 0

    payload = _read_stdin_json()
    # The pending-job check below is the loop guard: we block ONLY while a real job is 'open', and the
    # server/CLI caps (see the note further down) guarantee that record becomes terminal. We do NOT use
    # stop_hook_active as a ceiling — a single long discussion legitimately spans many stops.
    session_id = str(payload.get("session_id") or "")

    rec = _pending_job_for_session(session_id)
    if not rec or rec.get("status") != "open" or not rec.get("job_id"):
        return 0  # no open commander job for this session → let the stop proceed

    job_id = str(rec["job_id"])
    # NOTE on termination (no dead guard here by design): the loop CANNOT spin forever because the
    # only way to keep an 'open' record is a non-terminal server poll, and BOTH ends now cap that —
    # the server ages a stranded job to a terminal state (sweep_expired_queued_jobs / sweep_stale_
    # calling_jobs) AND the CLI self-expires the pending record past a wall-clock ceiling (_pending_
    # expired). Either one clears pending → the next stop is allowed. stop_hook_active is intentionally
    # NOT used as a ceiling (a single long discussion legitimately spans many turns); the caps above
    # are the real terminators.

    # BLOCK + inject the re-poll command. Declarative phrasing + the literal command (desktop fallback).
    reason = (
        "A voice discussion with Maya about this task is still in progress (commander job "
        f"{job_id}). Before stopping, the agreed instruction should be retrieved by running this "
        f"command with the Bash tool and waiting for it:\n\n    maya discuss --poll {job_id}\n\n"
        "If it prints an instruction, follow it as the authoritative next step. If it prints a "
        "PENDING line, the discussion is still going — stopping now is fine; it will be picked up "
        "on the next turn."
    )
    _log_seam("hook-blocked", job_id)  # the trigger-rate denominator (M3 GO/NO-GO measurement)
    print(json.dumps({"decision": "block", "reason": reason}))
    return 0


if __name__ == "__main__":
    sys.exit(main())
