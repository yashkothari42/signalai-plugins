---
name: backtest-strategy
description: Write a Python trading strategy and backtest it on SignalAI, then interpret the results honestly. Use when the user wants to backtest a strategy or idea, test a trading rule on historical data, or asks how a strategy would have performed.
---

# Backtest a strategy with SignalAI

Write a strategy, submit it, poll for results, then interpret them critically.

## 1. Write the strategy

Strategies subclass `signalai_quant.Strategy`. Minimal shape:

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

## 2. Submit and poll

Call `submit_backtest(strategy_src=<the code>, symbols=["AAPL"], start="2015-01-01",
end="2024-12-31", resolution="daily")`. It returns `{backtest_id, status:"queued"}`.

Then poll `get_backtest(backtest_id)` until `status == "done"` (or `"error"` —
report the `error`). Don't spam it; a few seconds between polls is plenty.

## 3. Interpret honestly

`summary_stats` has `total_return`, `max_drawdown`, `sharpe`. When you report:

- **A green equity curve is not a good strategy.** Always pair return with
  `max_drawdown` and `sharpe`; a high return with a huge drawdown is fragile.
- **Beware overfitting.** If the user tuned rules/dates to make it look good, say so.
  Suggest testing on a *different* period or symbol the rule wasn't tuned on.
- **In-sample only.** One backtest over one window proves little. Recommend an
  out-of-sample check before trusting it.
- **Costs & fills.** Frictionless assumptions flatter results; real fills/slippage
  drag returns, especially for high-turnover intraday rules.

Lead with the numbers, then the caveats, then a concrete next step (out-of-sample
run, simplify the rule, or compare to buy-and-hold).
