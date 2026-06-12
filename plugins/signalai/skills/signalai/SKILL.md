---
name: signalai
description: Overview of SignalAI in Claude — the signals, backtests, and strategies tools and when to use each. Use when the user mentions SignalAI, wants to build or backtest a trading signal or strategy, or asks what SignalAI can do.
---

# SignalAI

SignalAI lets you build live data **signals**, write trading **strategies** over
them, and **backtest** strategies on real historical market data — all from Claude
via the connected MCP tools. Everything is scoped to the signed-in user's account.

## The tools, grouped

**Signals** (a signal = a scheduled number stream, e.g. "AAPL 20-day momentum"):
- `list_signals` — the user's signals (name, status, last datapoint).
- `get_signal_history` — recent datapoints for one signal.
- `create_signal_from_prompt` / `send_signal_session_message` — build a new signal
  through an interactive agent session.

**Backtests** (run a Python strategy over history):
- `submit_backtest` — queue a backtest; returns a `backtest_id` immediately.
- `get_backtest` — poll status + `summary_stats`.
- `list_backtests` — recent runs.

**Strategies** (saved decision logic over signals):
- `list_strategies`, `get_strategy`.

## When to use which

- "Backtest this idea / strategy on AAPL" → use the **backtest-strategy** skill.
- "Build a signal that tracks X" → use the **build-signal** skill.
- "What are my signals / how did my backtest do?" → call `list_signals` /
  `list_backtests` / `get_backtest` directly and summarize.

Always report results plainly and flag caveats — see the backtest-strategy skill for
how to read a backtest honestly.
