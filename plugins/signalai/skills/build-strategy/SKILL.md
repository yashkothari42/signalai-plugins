---
name: build-strategy
description: Author a typed trading strategy for SignalAI from a plain-English idea, then save and version it. Use when the user wants to turn a trading hypothesis into testable rules, build or refine a strategy, or asks you to write strategy code before backtesting. You write the code (choosing Swing or Day), save it with save_strategy, and hand off to run-backtest.
---

# Build a strategy

You author the strategy code yourself, from the user's idea, and save it with the
`save_strategy` tool. The backend never runs your code — the first backtest is what
proves it works. When the strategy is saved, hand off to **run-backtest**.

## 0. Shape the idea

If the user only has a hunch, make it a *testable, economically-motivated* rule with
explicit **entry, exit, and sizing**. Keep it simple — fewer rules and fewer knobs
backtest more honestly. Starting points: momentum (buy above an N-day average, exit
below), mean reversion (buy X% below the mean, exit at it), MA crossover. Resist
piling on conditions to make it look good — that's overfitting.

## 1. Pick the trading type — this comes first

Every strategy is **Swing** or **Day** (only these two are supported; never write
Investing or HFT). Ask which fits the idea:

- **Swing** — holds across days, carries overnight, compounds as one book. *"Hold it
  for days/weeks until a condition flips."* → subclass `SwingStrategy`.
- **Day** — never holds overnight; flat at the session close, fixed cash each day,
  evaluated as an additive per-day book. *"Trade during the session, go home flat."*
  → subclass `DayStrategy`. The platform arms a session-liquidation guardrail
  automatically.

The type changes how the strategy is accounted, so pick the one that matches how the
user would actually trade it.

## 2. Write the code

Subclass the type's base class. Declare any tunable as a `ParamSpec` (so it becomes a
required, validated input at run time — read it with `self.param(name)`):

```python
from signalai_quant import SwingStrategy, Bar, Side, ParamSpec, IntParam


class Momentum(SwingStrategy):
    params = ParamSpec(lookback=IntParam(default=20, min=2, max=200))

    def init(self):
        # self.universe is the symbols the RUN configures — never hard-code symbols.
        self.history = {s: [] for s in self.universe}
        self.subscribe(Bar, self.on_bar)        # called once per bar

    def on_bar(self, bar: Bar):
        h = self.history[bar.symbol]
        h.append(bar.close)
        n = self.param("lookback")
        if len(h) < n:
            return
        avg = sum(h[-n:]) / n
        pos = self.portfolio[bar.symbol].qty
        if bar.close > avg and pos == 0:
            self.order(bar.symbol, Side.BUY, 10)
        elif bar.close < avg and pos > 0:
            self.order(bar.symbol, Side.SELL, pos)
```

Core API (this is the whole surface — don't invent methods):
- `init()` — set up state + subscriptions. `self.subscribe(Bar, handler)` for all bars,
  or `self.subscribe(MarketData(symbol, resolution), handler)` to route one symbol;
  `self.every("7d", cb)` for timers; `self.subscribe(OrderEvent, handler)` for fills.
- `self.order(symbol, Side.BUY|SELL, qty)` — the one order primitive (market by
  default). There is no `set_holdings`; size by computing a quantity.
- `self.param(name)` — the run-time value of a declared parameter.
- `self.universe` — the run's symbols. `self.portfolio[symbol].qty` — current position;
  `self.portfolio.equity(self._last_prices)` — equity for sizing.
- A `DayStrategy` uses the same API; just never assume overnight carry.

The platform prevents lookahead, but **your logic can still curve-fit** — keep it simple.

## 3. Save it

When the user is happy, call **`save_strategy`** with the source, a name (propose one
from the logic, or ask), and the trading type. Saving is required before a backtest can
reference it. Each later change → call `save_strategy` again with the same `strategy_id`
to record a **new version**; a brand-new idea → save without a `strategy_id` for a new
strategy. (Exact tool parameters are in the `save_strategy` tool description.)

## 4. Run it — hand off to run-backtest

To backtest, ensure the strategy is saved, then use **run-backtest**: it needs a
universe, a date range, starting cash, and a value for every declared parameter. The
first run is the real proof the code executes — if it errors, fix it and save a new
version.

## The honesty boundary (non-negotiable)

Author the user's *stated* rule. **Never tune parameters to make the backtest look
better** — no searching values for a higher return. That's overfitting, and it makes the
backtest lie. Report results neutrally and let **analyze-backtest** read them honestly.
