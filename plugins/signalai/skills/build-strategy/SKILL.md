---
name: build-strategy
description: Author a typed **Rust** trading strategy for SignalAI from a plain-English idea, then save and version it. Use when the user wants to turn a trading hypothesis into testable rules, build or refine a strategy, or asks you to write strategy code before backtesting. You write the Rust code (choosing Swing or Day), save it with save_strategy, and hand off to run-backtest.
---

# Build a strategy

You author the strategy in **Rust** — the SignalAI engine is a native Rust engine; there
is no Python path. The backend **compiles and runs** your code; the first backtest is what
proves it compiles and executes. When it's saved, hand off to **run-backtest**.

## 0. Shape the idea

If the user only has a hunch, make it a *testable, economically-motivated* rule with
explicit **entry, exit, and sizing**. Keep it simple — fewer rules and fewer knobs
backtest more honestly. Starting points: momentum (buy above an N-day average, exit
below), mean reversion (buy X% below the mean, exit at it), MA crossover. Resist piling
on conditions to make it look good — that's overfitting.

## 1. Pick the trading type — this comes first

Every strategy is **Swing** or **Day** (only these two; never Investing or HFT):

- **Swing** — holds across days, carries overnight, compounds as one book. This is the
  default: just don't override `trading_type`.
- **Day** — never holds overnight; flat at the session close, fixed cash each day,
  additive per-day book. Add `fn trading_type(&self) -> TradingType { TradingType::Day }`.
  The engine **force-flats every position at each session close automatically** — you
  don't write the liquidation.

## 2. Write the Rust code — the exact contract

Strategies are authored against the **`signalai-quant`** crate (the public API — the
engine itself runs server-side). Your source must:
1. start with `use signalai_quant::prelude::*;`
2. define a struct that `impl Strategy`, and
3. a `pub fn build_strategy() -> Box<dyn Strategy>`.

Nothing else — no `fn main`, no `mod`, no extra crates. (Locally, `cargo add signalai-quant`
gives full type-checking + IDE support; the server compiles the *same* source.)

```rust
use signalai_quant::prelude::*;

struct Momentum { sma: indicators::Sma, sym: SymbolId }

impl Strategy for Momentum {
    fn init(&mut self, ctx: &mut Ctx) {
        self.sym = ctx.universe()[0];            // the RUN's symbols — never hard-code tickers
        ctx.subscribe_bars(self.sym, Resolution::Day1);
    }
    fn on_bar(&mut self, ctx: &mut Ctx, bar: &Bar) {
        let close = bar.close.as_f64();
        let Some(avg) = self.sma.update(close) else { return }; // None until warm
        let holding = !ctx.position(self.sym).is_zero();
        if close > avg && !holding {
            let shares = (ctx.cash() / close).floor();          // size from available cash
            ctx.order(self.sym, Side::Buy, Qty::shares(shares));
        } else if close < avg && holding {
            ctx.liquidate(self.sym);
        }
    }
}

pub fn build_strategy() -> Box<dyn Strategy> {
    Box::new(Momentum { sma: indicators::Sma::new(20), sym: SymbolId(0) })
}
```

Core API — the whole surface, don't invent methods:

- **Handlers** on `impl Strategy`: `init(&mut self, ctx)` (required — subscribe + init
  state), `on_bar(ctx, bar)`, optional `on_order(ctx, ev)` (fills arrive here — orders do
  NOT fill inside a handler), `on_trade`/`on_quote`/`on_timer`. `fn trading_type()` →
  `TradingType::Swing` (default) or `::Day`.
- **Subscribe in `init`**: `ctx.subscribe_bars(sym, Resolution::Day1)` (or `Min1`);
  `ctx.every("7d")` for timers.
- **Orders** (market): `ctx.order(sym, Side::Buy|Sell, Qty::shares(n))`; `ctx.liquidate(sym)`;
  `ctx.set_target(sym, Qty::shares(n))` (engine computes the delta to reach that position).
- **Reads**: `ctx.universe()` → owned `Vec<SymbolId>` (the run's symbols); `ctx.cash()`,
  `ctx.equity()` → f64; `ctx.position(sym)` → `Qty` (use `.is_zero()`, `.as_f64()`);
  `ctx.last_price(sym)` → `Price`.
- **Fixed-point newtypes**: `Price`/`Qty` — read with `.as_f64()`, build with
  `Price::from_f64(x)` / `Qty::shares(n)` (**`shares` takes `f64`** — passing i64 is E0308).
  `bar.close.as_f64()`.
- **Indicators** (incremental, lookahead-free) — **`.update(x)` return type differs per
  indicator, do NOT assume `Option`:**
  - `indicators::Sma::new(n)` → `Option<f64>` (`None` until `n` samples).
  - `indicators::Rsi::new(n)` → `Option<f64>` (`None` until warm).
  - `indicators::Ema::new(n)` → **plain `f64`** (emits from bar 1, NOT `Option`). Bind it
    directly (`let ema = self.ema.update(x);`); `let Some(ema) = self.ema.update(x)` is a
    TYPE ERROR (E0308). EMA has no built-in warmup — gate crossovers with your own bar counter.
  - `indicators::Macd::new(fast, slow, signal)` → `Option<MacdValue>` (`None` until `slow`
    samples; fields `.macd .signal .histogram`).
  - `indicators::Bollinger::new(n, k)` → `Option<BollingerValue>` (`None` until `n`; fields
    `.upper .middle .lower` = SMA ± k·σ).
  - `indicators::Atr::new(n)` → `.update(high, low, close) -> Option<f64>` (Wilder; note the
    THREE-argument update).
  - `indicators::Vwap::new()` → `.update(price, volume) -> Option<f64>` (cumulative; call
    `.reset()` at each session open in DAY strategies).
  - `indicators::Stochastic::new(k_period, d_period)` → `.update(high, low, close) ->
    Option<StochasticValue>` (fields `.k .d`).
  - `indicators::RollingWindow::new(n)` → `.update(x)` returns `()`; read `.mean() .std()
    .min() .max() .last() .len()`.
- **SignalAI signals as inputs**: `ctx.subscribe_signal("name")` in `init`; implement
  `on_signal(&mut self, ctx, sig: &SignalValue)` (`sig.name`/`sig.ts`/`sig.value`). Push-only —
  NO `ctx.signal()` reader exists; to use the value in `on_bar`, store it in a struct field
  (`last_value: Option<f64>` set in `on_signal`). Points interleave with bars by ts — no
  lookahead; on_signal orders fill next bar open. The RUN must name the signals: pass
  `signals: ["name"]` to `run_backtest` (else no events arrive). The submit 400s if a named
  signal has no datapoints in the range.
- **Multi-symbol** is safe: `for s in ctx.universe() { … ctx.order(s, …) }` — `universe()`
  is owned, so ordering inside the loop does not conflict.

Compile-safety (from the authoring validation): gate **`Option`-returning** indicators (Sma/Rsi)
with `let Some(v) = ind.update(x) else { return };` — but bind EMA directly (`let v = ema.update(x);`,
it returns `f64`). Read ctx values into locals before calling `ctx.order(...)` (don't hold a borrow
across the order call). Keep state in your struct's fields.

The engine prevents lookahead, but **your logic can still curve-fit** — keep it simple.

## 3. Save it

Call **`save_strategy`** with the Rust `source`, a `name` (propose one from the logic),
and the `trading_type` ('swing'|'day', matching your `Strategy::trading_type`). For now
pass **`params_schema: []`** and use literal constants for tunables (e.g.
`Sma::new(20)`) — run-tier inputs (universe, dates, cash) come from the RUN; strategy-tier
tunable parameters aren't wired into the engine yet. Each later change → `save_strategy`
again with the same `strategy_id` (new version); a brand-new idea → save without one.

## 4. Run it — hand off to run-backtest

To backtest, ensure the strategy is saved, then use **run-backtest**: it needs a universe,
a date range, and starting cash. The first run is the real proof the code compiles and
executes — if it errors, the backtest comes back `failed` with the compiler message; fix
it and save a new version.

## The honesty boundary (non-negotiable)

Author the user's *stated* rule. **Never tune parameters to make the backtest look
better** — no searching values for a higher return. That's overfitting, and it makes the
backtest lie. Report results neutrally and let **analyze-backtest** read them honestly.
