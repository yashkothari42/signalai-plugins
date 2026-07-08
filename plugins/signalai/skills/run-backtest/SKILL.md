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

Backtests run **by reference** to a saved, versioned strategy — never inline code. If
the strategy isn't saved yet, save it first with **build-strategy** (`save_strategy`),
which returns a `strategy_id`. The first run is also what proves the code executes.

## 2. Run and poll

```text
run_backtest(strategy_id=<id>, symbols=["AAPL"],
             start="2015-01-01", end="2024-12-31", resolution="daily",
             params={...},        # a value for every required declared param
             signals=["my-sig"],  # ONLY if the strategy subscribes to signals
             execution={"preset": "retail"})  # cost model — see below
```

**Execution costs (`execution`)**: `{"preset": "retail"}` models a $0-commission broker with US
regulatory fees + realistic slippage/spread — **use it by default** so returns are honest. Other
presets: `ibkr-pro` (per-share commission), `conservative` (higher impact, small caps), `zero`
(frictionless — only for comparing against an older zero-cost run), `custom` (+field overrides).
Results include `total_fees` and `total_slippage_cost` — mention the cost drag when reporting.

`version` is optional (defaults to the latest). If the strategy uses
`ctx.subscribe_signal`/`on_signal`, you MUST pass the signal names in `signals` —
otherwise no signal events reach it. The submit fails clearly if a named signal has
no datapoints in the range; the result's `params.signals` shows the coverage the run
saw ({points, first, last} per signal) — mention it when reporting. Returns
`{backtest_id, status: "queued"}`. Then poll `get_backtest(backtest_id)` until
`status == "done"` (or `"error"` — report the `error`). Don't spam it; a few seconds
between polls is plenty.

## 3. Hand off

When it's `done`, switch to **analyze-backtest** with the `backtest_id` to read the
`summary_stats` honestly and decide whether to improve it.
