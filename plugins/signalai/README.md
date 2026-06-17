# SignalAI for Claude

Build, backtest, and inspect trading signals from Claude. This plugin bundles the
SignalAI MCP connector with playbook skills that teach Claude to use it well.

## Install (Claude Code)

```
/plugin marketplace add yashkothari42/signalai-plugins
/plugin install signalai
```

On first tool use, Claude opens a browser to sign in (the same account as the web
app). Then ask, e.g.: *"Backtest a momentum strategy on AAPL from 2015 to 2024 and
tell me the return, Sharpe, and drawdown."*

## Use in claude.ai / Claude Desktop

Add the connector at **Settings → Connectors → Add custom connector** with the URL
`https://35.94.249.241.sslip.io/mcp/`, then load the skills from this folder. See the
[Connect docs](https://signal-ai-mu.vercel.app/docs/connect).

## Skills

- **signalai-guide** — overview + which skill to use for what.
- **build-signal** — drive the interactive signal builder.
- **debug-signal** — diagnose a signal that's empty, stalled, or down.
- **build-strategy** — shape an idea and write the strategy code.
- **run-backtest** — submit a backtest and poll for results.
- **analyze-backtest** — read results honestly and improve them without overfitting.

## Staying up to date

The SignalAI plugin improves over time (new skills, refined guidance). Two ways to stay current:

- **Auto-update (recommended):** in Claude Code run `/plugin`, open **Marketplaces**,
  select **signalai**, and enable **auto-update**. New versions then arrive on launch.
- **Manual:** run `/plugin marketplace update signalai && /reload-plugins` whenever you
  want the latest.

When you're behind, the plugin will quietly remind you at the start of a session.
