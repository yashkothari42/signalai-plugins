---
name: build-signal
description: Build a new SignalAI data signal through the interactive builder. Use when the user wants to create or track a signal, e.g. "track BTC price every minute" or "make a signal for AAPL 20-day momentum".
---

# Build a signal with SignalAI

A signal is a scheduled number stream from a data source. Building one runs an
interactive agent session — drive it with two tools.

## Start the build

Call `create_signal_from_prompt(prompt=<clear description>)`. A good prompt names the
**source/metric**, the **cadence**, and any **transform**, e.g.
"BTC price in USD from Coinbase, every minute" or "AAPL % deviation from its 20-day
mean, daily". It returns:

- `session_id` — keep it for follow-ups.
- `agent_message` — show this to the user verbatim.
- `phase` — one of `discovery` | `choice` | `deployed` | `still_building` | `failed`.
- `choices` — present when `phase == "choice"`.
- `build_url` — a deep link to the web builder UI.

## Continue the session

Based on `phase`:

- **discovery** — the agent is asking a question. Relay it, get the user's answer,
  then `send_signal_session_message(session_id, message=<answer>)`.
- **choice** — present the `choices` list; send the chosen choice's `id` back via
  `send_signal_session_message`.
- **still_building** — it's working; either call `send_signal_session_message(session_id,
  "continue")` to advance a turn, or hand off the `build_url`.
- **deployed** — done; report the new `signal_id` and that it's live.
- **failed** — report the failure and offer to retry or open the `build_url`.

When the conversation gets visual or stuck, offer the `build_url` so the user can
finish in the richer web UI — the session is shared.
