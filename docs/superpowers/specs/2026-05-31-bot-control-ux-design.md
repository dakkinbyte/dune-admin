# Bot Control UX — Consolidated Panel & Dormant Mode

**Date:** 2026-05-31
**Status:** Approved

## Problem

When the embedded bot is disabled in Settings (`market_bot_enabled: false`), `embeddedBot`
is `nil` at runtime, so `handleMarketBotStatus` returns `mode: "none"`. The Market tab
hides the "Bot Control" button on `mode === "none"`, making Wipe Listings inaccessible.
This is the exact moment you need it (recovery from category-tree poisoning requires
wipe → hash reset → re-enable).

A second irritation: bot config is split across two surfaces. Settings has
`market_bot_enabled` (a restart-required config flag) and the Bot Control panel has a
runtime enable toggle — two levers for what users assume is one thing.

## Goals

1. Bot Control button visible whenever a bot is *configured*, regardless of running state.
2. Dormant mode in the panel when configured-but-disabled: Wipe Listings + enable toggle
   remain functional; lifecycle actions (start/stop/restart) are hidden.
3. Single source of truth for bot enable/disable: remove `market_bot_enabled` from
   Settings. The panel's enable toggle remains.
4. No behaviour changes to the file-path / remote-URL fields in Settings (those remain
   restart-required config and stay where they are).

## Architecture

### Backend — `configured` field in status response

`handleMarketBotStatus` (`handlers_market_bot.go`) adds a boolean `configured` to every
response branch:

| State | `mode` | `configured` |
|---|---|---|
| `embeddedBot != nil` | `"embedded"` | `true` |
| `remoteBotProxy != nil` | `"remote"` | `true` |
| neither, but `embeddedBotConfigured` is set | `"none"` | `true` |
| totally unconfigured | `"none"` | `false` |

A new package-level bool `embeddedBotConfigured` is set to `true` in
`startEmbeddedMarketBotIfEnabled` whenever `marketBotEnabled(cfg)` is true (i.e., the
config says the embedded bot should exist, even if it fails to start). It is never reset
to `false` at runtime so the button persists across bot restarts.

The `configured: bool` field is added to the `BotStatus` TypeScript type in
`web/src/api/client.ts`.

No new endpoint; no DB query; no startup cost.

### Frontend — button visibility

`MarketTab/index.tsx` replaces `botConnected` with `botConfigured`:

```ts
const [botConfigured, setBotConfigured] = useState(false)
// …
.then((s) => setBotConfigured(s.configured ?? s.mode !== 'none'))
```

The `?? s.mode !== 'none'` fallback handles older backends gracefully.

The hint text shown when no bot is present only appears when `!botConfigured`.

### Frontend — BotControlPanel dormant mode

`BotControlPanel` receives the `BotStatus` once loaded. When `status.mode === 'none'`
(configured but not running):

- **BotStatusCard** shows a "Bot disabled" state.
- **BotActions** hides start/stop/restart buttons; shows only "Enable in config" hint and
  the Wipe Listings button (which calls `api.marketBot.cleanup()` — already ungated in
  the API).
- Config and Disabled Items tabs still render (read-only is fine; saving config still
  works even when dormant).
- Logs tab shows "Bot not running — no logs available."

`BotActions` gates lifecycle buttons on `status.mode !== 'none'`.

### Settings — remove `market_bot_enabled`

Remove the `market_bot_enabled` checkbox and its surrounding section header from
`SettingsConfigForm.tsx`. The EMPTY default and `pointerBoolFields` set entries are also
removed. The underlying `market_bot_enabled` config key still works from the YAML/env —
it just no longer has a UI toggle in Settings. Users enable/disable via the panel.

File-path fields (`market_bot_cache_db`, `market_bot_item_data`, `market_bot_state`) and
the remote-bot fields stay in Settings unchanged.

## Files Modified

| File | Change |
|---|---|
| `cmd/dune-admin/main.go` | Add `embeddedBotConfigured bool` global; set in `startEmbeddedMarketBotIfEnabled` |
| `cmd/dune-admin/handlers_market_bot.go` | Add `configured` to all three status response branches |
| `cmd/dune-admin/handlers_market_bot_test.go` | Test `configured` field for each branch |
| `web/src/api/client.ts` | Add `configured?: boolean` to `BotStatus` type |
| `web/src/tabs/MarketTab/index.tsx` | `botConnected` → `botConfigured`; derive from `s.configured` |
| `web/src/tabs/MarketTab/bot/BotControlPanel.tsx` | Pass `mode` down; handle dormant render |
| `web/src/tabs/MarketTab/bot/BotActions.tsx` | Gate lifecycle buttons on `mode !== 'none'`; show Wipe always |
| `web/src/components/SettingsConfigForm.tsx` | Remove `market_bot_enabled` toggle + EMPTY entry |

## Testing

- Go: new test cases in `handlers_market_bot_test.go` covering `configured=true` when
  `embeddedBotConfigured=true && embeddedBot=nil`, and `configured=false` when neither
  global is set. Run `make verify`.
- Frontend: `pnpm lint` in `web/`. Manual: disable bot in Settings → confirm button
  still appears → open panel → confirm Wipe Listings is active → confirm start/stop
  hidden.
