# Bot Server Config Consolidation

**Date:** 2026-05-31
**Status:** Approved

## Problem

The Market Bot tab in Settings still holds five fields that belong with the bot:

- `market_bot_cache_db` — cache DB path
- `market_bot_item_data` — item data JSON path
- `market_bot_state` — state file path
- `market_bot_remote_url` — remote bot URL
- `market_bot_remote_token` — remote bot token

These are restart-required server config values (written to `~/.dune-admin/config.yaml`
via `POST /api/v1/config`), but they're logically bot settings and should live in the
Bot Control panel alongside everything else. After this change there will be zero
bot-related UI in Settings.

## Design

### New component — `BotServerConfig.tsx`

`web/src/tabs/MarketTab/bot/BotServerConfig.tsx`

Loads the full `AppConfig` via `api.config.get()`, lets the user edit the five
market-bot server-config fields, and saves the full config back via `api.config.save()`.

Behaviour:

- Fetches on mount; shows a spinner while loading.
- Input fields use the same inline-styled pattern as the rest of the project
  (`bg-surface border border-border rounded px-2 py-1.5 text-sm ...`).
- Password field for `market_bot_remote_token` with placeholder `••••••••` when
  the value matches the `MASKED` sentinel from `api/client.ts`.
- A "Save" button triggers save; shows success toast on save. Toast message includes
  "restart required to apply".
- A `<p className="text-xs text-muted">` restart-required note above the save button.
- Does not use `EMPTY` or `mergeConfig` from SettingsConfigForm — load/save is
  self-contained.

Fields shown:

| Label | Key | Input type |
|---|---|---|
| Cache DB | `market_bot_cache_db` | text, placeholder `~/.dune-admin/market-bot-cache.db` |
| Item data | `market_bot_item_data` | text, placeholder `item-data.json` |
| State path | `market_bot_state` | text, placeholder `~/.dune-admin/market-bot-state.json` |
| Remote URL | `market_bot_remote_url` | text, placeholder `http://host:9191` |
| Remote token | `market_bot_remote_token` | password, placeholder `MASKED` |

Sections: "Embedded Bot" (cache DB, item data, state) and "Remote Bot" (URL, token),
each under a `SectionLabel` from `dune-ui`.

### BotControlPanel — add "Server" tab

`web/src/tabs/MarketTab/bot/BotControlPanel.tsx`

Add a fourth tab "Server" between "Disabled Items" and "Logs":

```
Config | Disabled Items | Server | Logs
```

The Server tab panel renders `<BotServerConfig />`. The tab is always visible
(regardless of bot mode — the whole point is to be accessible when dormant).

### Settings — remove Market Bot tab

`web/src/components/SettingsConfigForm.tsx`

Remove the `<Tabs.Tab id="marketbot">` entry and its corresponding
`<Tabs.Panel id="marketbot">` block entirely.

**Do not** remove the `market_bot_*` fields from `EMPTY` or `AppConfig` type — they
must remain in `EMPTY` so that a Settings save does not blank out the values (the form
sends the full config; absent keys get their EMPTY default rather than the real file
value). The fields are silently preserved even though they're no longer shown.

## Files

| File | Change |
|---|---|
| `web/src/tabs/MarketTab/bot/BotServerConfig.tsx` | Create |
| `web/src/tabs/MarketTab/bot/BotControlPanel.tsx` | Add Server tab + import |
| `web/src/components/SettingsConfigForm.tsx` | Remove Market Bot tab + panel |

## Verification

- `cd web && pnpm lint` passes.
- Settings → no Market Bot tab visible.
- Bot Control panel → Server tab loads the five fields with their current values.
- Editing a field and saving shows success toast "…restart required to apply".
- After save, re-opening the Server tab shows the saved values (confirming round-trip).
