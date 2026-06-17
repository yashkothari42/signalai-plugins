---
name: signalai-guide
description: Overview of SignalAI in Claude and which skill to use for what. Use when the user mentions SignalAI, wants to build/backtest/debug a trading signal or strategy, or asks what SignalAI can do.
---

# SignalAI — guide

SignalAI lets you build live data **signals**, write trading **strategies** over
them, and **backtest** strategies on real historical market data — all from Claude
via the connected MCP tools. Everything is scoped to the signed-in user's account.

**Signal vs strategy:** a *signal* is a scheduled number stream (e.g. "AAPL 20-day
momentum, daily"). A *strategy* is Python decision logic that trades over price/signal
history and is evaluated by a *backtest*. Build signals first; strategies consume them.

## The tools, grouped

**Signals:** `list_signals` (your signals + status + last datapoint),
`get_signal_history` (recent datapoints), `create_signal_from_prompt` /
`send_signal_session_message` (interactive build).

**Backtests:** `submit_backtest` (queue a run → `backtest_id`), `get_backtest`
(poll status + `summary_stats`), `list_backtests` (recent runs).

**Strategies:** `list_strategies`, `get_strategy` (saved decision logic).

## Which skill to use

| The user wants to… | Use skill |
|---|---|
| Create / track a new signal | **build-signal** |
| Fix a signal that's empty, stalled, or down | **debug-signal** |
| Come up with or write a trading strategy | **build-strategy** |
| Run a backtest on a strategy | **run-backtest** |
| Read backtest results, or improve them | **analyze-backtest** |
| Just list things / check status | call `list_*` / `get_*` directly and summarize |

Always report results plainly and flag caveats — see **analyze-backtest** for how to
read a backtest honestly.
