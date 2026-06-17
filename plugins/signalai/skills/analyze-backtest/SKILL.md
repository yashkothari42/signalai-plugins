---
name: analyze-backtest
description: Interpret SignalAI backtest results honestly and improve them without overfitting. Use when the user asks how a backtest did, wants the results explained, or wants to make a strategy perform better.
---

# Analyze + improve a backtest

Read the result critically first, then iterate honestly.

## 1. Read it honestly

`summary_stats` has `total_return`, `max_drawdown`, `sharpe`. When you report:

- **A green equity curve is not a good strategy.** Always pair return with
  `max_drawdown` and `sharpe`; high return + huge drawdown is fragile.
- **In-sample only.** One backtest over one window proves little.
- **Costs & fills.** Frictionless assumptions flatter results; real fills/slippage drag
  returns, especially for high-turnover intraday rules.
- **Compare to a benchmark.** Beating buy-and-hold matters more than a big raw number.

Lead with the numbers, then the caveats.

## 2. Diagnose weakness

Name *why* it's weak before changing anything:
- Big `max_drawdown` → no risk control / position too large.
- Low/negative `sharpe` → return isn't compensating for volatility.
- Very few trades → result is luck, not edge.
- Great in one window, bad in another → regime-dependent / fragile.

## 3. Improve — without cheating

**Legitimate moves:** simplify the rule (fewer parameters), add risk management
(stops, smaller/volatility-scaled sizing), test the *same* rule across other symbols
and other periods, and compare to buy-and-hold.

**Overfitting discipline (the line you must not cross):**
- Tweaking rules/parameters to fit the *same* window is curve-fitting. After any
  change, re-validate on a **different period or symbol** the rule wasn't tuned on
  (re-run via **run-backtest**).
- Prefer fewer parameters. Distrust a big improvement from a tiny tweak.
- "Better" = better *risk-adjusted* (sharpe), survives out-of-sample, and beats the
  benchmark — **not** just a higher return on the tuned window.

## 4. Know when to stop

If it only works on one cherry-picked window, or needs many parameters to look good,
say so and recommend abandoning or radically simplifying it. An honest "this doesn't
have an edge" is a real result.
