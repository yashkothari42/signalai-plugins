---
name: run-backtest
description: Submit a SignalAI backtest and poll for results. Use when the user has a strategy and wants to run it over historical data, or says "backtest this on <symbol>".
---

# Run a backtest

Pick a fair test, submit, and poll. Then hand off to **analyze-backtest** to interpret.

## 1. Set up a fair test

Before spending a run, settle:
- **Symbols** — what the strategy actually trades (e.g. `["AAPL"]`).
- **Window** — a `start`/`end` the user did *not* hand-pick to flatter the result. A
  multi-year daily window is a sane default (e.g. 2015-01-01 → 2024-12-31).
- **Resolution** — `daily` for long-horizon ideas; `minute` for intraday (intraday has
  per-day reset + flat-overnight semantics).

If the strategy was just written, confirm it builds (see **build-strategy** /
`signalai check`) — submitting a strategy that doesn't build wastes a run and returns
`status: "error"`.

## 2. Submit and poll

```text
submit_backtest(strategy_src=<the code>, symbols=["AAPL"],
                start="2015-01-01", end="2024-12-31", resolution="daily")
```

Returns `{backtest_id, status: "queued"}`. Then poll `get_backtest(backtest_id)` until
`status == "done"` (or `"error"` — report the `error`). Don't spam it; a few seconds
between polls is plenty.

## 3. Hand off

When it's `done`, switch to **analyze-backtest** with the `backtest_id` to read the
`summary_stats` honestly and decide whether to improve it.
