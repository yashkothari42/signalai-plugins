---
name: debug-signal
description: Diagnose a SignalAI signal that is empty, stalled, or down. Use when the user says a signal stopped updating, shows no data, returns zeros, or looks broken.
---

# Debug a signal

Diagnose from what the tools actually expose, then give one concrete next step.
Be honest about the limit: via MCP you can see **status + datapoint history**, but
**not** container logs or source errors — so you can usually identify the *likely*
cause, not always prove it.

## 1. Gather

- `list_signals` → find the signal; note `status` (`live` / `stalled` / `down`) and
  the age of its last datapoint.
- `get_signal_history` → look at recent datapoints: are they zeros? Are there gaps?
  When did the last real value land?

## 2. Symptom → likely cause

| What you see | Likely cause | Next step |
|---|---|---|
| `status: down`, no recent datapoints | Container crashed / OOM / not scheduled | Rebuild via the `build_url`, or check back shortly — the reconciler may restore it |
| `status: stalled`, last datapoint hours/days old | Source quota burned (e.g. a news/API key), schedule too slow, or the source changed shape | Open `build_url` to inspect the source step; consider a slower cadence or a different source |
| History empty or all zeros | Source returning nothing, API shape changed, or the transform drops everything | Rebuild and re-test the scraper/transform in the web builder (`build_url`) |
| Intermittent gaps | Flaky / rate-limited source | Often expected; confirm cadence vs the source's real update rate |

## 3. Report

State (a) what's observable, (b) the single most likely cause, (c) one concrete
next step — usually "open the build UI to inspect/repair" (hand off the `build_url`
from `list_signals`/the build session) or "rebuild the signal." Say plainly when you
can't see enough to be certain.
