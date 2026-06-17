# SignalAI for Claude

Build, backtest, and inspect trading **signals** and **strategies** from inside Claude.
This is the public marketplace for the SignalAI Claude plugin: it bundles the SignalAI
**MCP connector** with playbook **skills** that teach Claude to use it well.

> Source of truth is [signal-ai-mu.vercel.app](https://signal-ai-mu.vercel.app).
> Full connect guide: [/docs/connect](https://signal-ai-mu.vercel.app/docs/connect).

## Install (Claude Code)

```
/plugin marketplace add yashkothari42/signalai-plugins
/plugin install signalai
```

The first tool call opens a browser for a one-time Google sign-in (the same account as
the web app). Then ask, e.g. *"Backtest a momentum strategy on AAPL from 2015 to 2024
and tell me the return, Sharpe, and drawdown."*

## Use in claude.ai or Claude Desktop

Plugins are a Claude Code feature. On the web or desktop apps, add the connector by hand:
**Settings → Connectors → Add custom connector**, paste the SignalAI MCP URL
`https://35.94.249.241.sslip.io/mcp/`, and sign in. You get the same nine tools (the
skills are Claude Code only).

## What's inside

**Nine MCP tools**, grouped:
- Signals: `list_signals`, `get_signal_history`, `create_signal_from_prompt`, `send_signal_session_message`
- Backtests: `submit_backtest`, `get_backtest`, `list_backtests`
- Strategies: `list_strategies`, `get_strategy`

**Six skills** (Claude Code):
- `signalai-guide` — overview and routing
- `build-signal` — create a signal through the interactive builder
- `debug-signal` — diagnose a signal that's empty, stalled, or down
- `build-strategy` — shape an idea and write the strategy
- `run-backtest` — submit a backtest and poll for results
- `analyze-backtest` — read results honestly and improve them without overfitting

## Staying up to date

In Claude Code, run `/plugin`, open **Marketplaces**, select **signalai**, and enable
**auto-update** so new versions arrive on launch. Or update manually any time with
`/plugin marketplace update signalai && /reload-plugins`. When you're behind, the plugin
quietly reminds you at the start of a session.

Everything is scoped to your account. Backtests use real market data, not live trades.
Not financial advice.
