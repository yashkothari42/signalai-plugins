---
name: build-strategy
description: Shape a trading idea and write a Python strategy for SignalAI. Use when the user wants strategy ideas, wants to turn a hypothesis into testable rules, or needs to write the strategy code before backtesting.
---

# Build a strategy

Turn an idea into a clean, testable `signalai_quant.Strategy`. Then hand off to
**run-backtest**.

## 0. Shape the idea (if it's vague)

If the user only has a hunch, make it a *testable, economically-motivated* rule with
explicit entry, exit, and sizing. Keep it simple — fewer rules and parameters
backtest more honestly. Starting points:

- **Momentum:** buy when price > its N-day moving average; exit when it crosses back.
- **Mean reversion:** buy when price is X% below its N-day mean; exit at the mean.
- **MA crossover:** go long when a fast MA crosses above a slow MA.

Tie it to a real symbol the user cares about (e.g. AAPL, SPY) and a plausible holding
period. Resist piling on conditions to "make it work" — that's overfitting, which
**analyze-backtest** will call out later.

## 1. Write the strategy

Strategies subclass `signalai_quant.Strategy`:

```python
from signalai_quant import Strategy, Bar, Side, OrderType


class Momentum(Strategy):
    def init(self):
        self.subscribe(Bar, self.on_bar)   # called once per bar

    def on_bar(self, bar):
        # bar.symbol, bar.close, bar.timestamp
        if self.portfolio[bar.symbol].qty == 0:
            self.order(bar.symbol, Side.BUY, 10, OrderType.MARKET)
```

Key API:
- `init()` — set up subscriptions (`self.subscribe(Bar, handler)`) and timers
  (`self.every("1d", cb)`).
- `self.order(symbol, Side.BUY|SELL, qty, OrderType.MARKET, price=None)`.
- `self.set_holdings(symbol, target_pct)` — size to a fraction of equity.
- `self.portfolio[symbol].qty` — current position; `self.portfolio.equity(prices)`.

The engine prevents lookahead (orders never fill on data they couldn't have seen) —
but **your logic can still curve-fit**. Keep rules simple and economically motivated.

## 2. Make sure it builds

The source must define a `Strategy` subclass with an `init()` that subscribes to
something. An invalid strategy fails at run time with `status: "error"`. CLI users can
verify locally first with `signalai check <file>` (requires `pip install signalai-quant`).

When the code is ready, move to the **run-backtest** skill.
