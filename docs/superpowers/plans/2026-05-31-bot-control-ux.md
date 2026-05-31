# Bot Control UX — Consolidated Panel & Dormant Mode

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Show the Bot Control button and panel whenever the bot is configured (even when disabled), surface Wipe Listings in the dormant state, and remove the duplicate enable toggle from Settings.

**Architecture:** Add `embeddedBotConfigured bool` global set at startup (never cleared), expose `configured` in the status API, drive button visibility and panel dormant mode from that field in the frontend, remove the `market_bot_enabled` checkbox from the Settings form.

**Tech Stack:** Go (package main, flat), React + TypeScript, HeroUI v3 via dune-ui wrappers.

---

## File Map

| File | Change |
|---|---|
| `cmd/dune-admin/main.go` | Add `embeddedBotConfigured bool` global; set it in `startEmbeddedMarketBotIfEnabled` |
| `cmd/dune-admin/handlers_market_bot.go` | Emit `configured` in all three status branches |
| `cmd/dune-admin/handlers_market_bot_test.go` | Tests for the three `configured` cases; fix existing tests to reset the new global |
| `web/src/api/client.ts` | Add `configured?: boolean` to `BotStatus` type |
| `web/src/tabs/MarketTab/index.tsx` | `botConnected` → `botConfigured`; derive from `s.configured` |
| `web/src/tabs/MarketTab/bot/BotActions.tsx` | Hide lifecycle buttons when `mode === 'none'`; Wipe always visible |
| `web/src/components/SettingsConfigForm.tsx` | Remove `market_bot_enabled` CB; add explanatory note |

---

## Task 1 — Backend: `embeddedBotConfigured` global + status `configured` field

**Files:**

- Modify: `cmd/dune-admin/main.go` (near line 701 where `embeddedBot` is declared; and inside `startEmbeddedMarketBotIfEnabled` at line 622)
- Modify: `cmd/dune-admin/handlers_market_bot.go` (lines 79–132, all three status branches)

- [ ] **Step 1: Add the global and set it at startup**

In `cmd/dune-admin/main.go`, add the global immediately after `embeddedBot` (around line 703):

```go
// embeddedBotConfigured is true whenever the server config has market_bot_enabled=true,
// regardless of whether the bot instance is currently running. Never reset to false.
var embeddedBotConfigured bool
```

In `startEmbeddedMarketBotIfEnabled` (line 622), set it before the early return:

```go
func startEmbeddedMarketBotIfEnabled(cfg appConfig) context.CancelFunc {
    if !marketBotEnabled(cfg) {
        return nil
    }
    embeddedBotConfigured = true   // ← add this line
    botCtx, botCancel := context.WithCancel(context.Background())
    // … rest unchanged
```

- [ ] **Step 2: Add `configured` to all three status response branches**

In `cmd/dune-admin/handlers_market_bot.go`, edit `handleMarketBotStatus`:

```go
// embedded branch (line ~88):
out["mode"] = "embedded"
out["configured"] = true           // ← add

// remote branch (line ~120):
out["mode"] = "remote"
out["running"] = true
out["enabled"] = true
out["configured"] = true           // ← add

// neither branch (line ~126):
jsonOK(w, map[string]any{
    "running":    false,
    "enabled":    false,
    "mode":       "none",
    "configured": embeddedBotConfigured, // ← was missing
    "error":      "market bot not configured; set market_bot_enabled: true or market_bot_remote_url",
})
```

- [ ] **Step 3: Write failing tests**

Add to `cmd/dune-admin/handlers_market_bot_test.go`:

```go
func TestHandleMarketBotStatus_ConfiguredButDisabled(t *testing.T) {
    origBot := embeddedBot
    origProxy := remoteBotProxy
    origCfg := embeddedBotConfigured
    embeddedBot = nil
    remoteBotProxy = nil
    embeddedBotConfigured = true // configured in YAML but not running
    defer func() {
        embeddedBot = origBot
        remoteBotProxy = origProxy
        embeddedBotConfigured = origCfg
    }()

    req := httptest.NewRequest("GET", "/api/v1/market-bot/status", nil)
    w := httptest.NewRecorder()
    handleMarketBotStatus(w, req)

    var body map[string]any
    if err := json.NewDecoder(w.Body).Decode(&body); err != nil {
        t.Fatalf("decode: %v", err)
    }
    if body["mode"] != "none" {
        t.Errorf("mode: got %v want 'none'", body["mode"])
    }
    if body["configured"] != true {
        t.Errorf("configured: got %v want true", body["configured"])
    }
}

func TestHandleMarketBotStatus_NeitherConfiguredNorEnabled(t *testing.T) {
    origBot := embeddedBot
    origProxy := remoteBotProxy
    origCfg := embeddedBotConfigured
    embeddedBot = nil
    remoteBotProxy = nil
    embeddedBotConfigured = false
    defer func() {
        embeddedBot = origBot
        remoteBotProxy = origProxy
        embeddedBotConfigured = origCfg
    }()

    req := httptest.NewRequest("GET", "/api/v1/market-bot/status", nil)
    w := httptest.NewRecorder()
    handleMarketBotStatus(w, req)

    var body map[string]any
    if err := json.NewDecoder(w.Body).Decode(&body); err != nil {
        t.Fatalf("decode: %v", err)
    }
    if body["configured"] != false {
        t.Errorf("configured: got %v want false", body["configured"])
    }
}
```

Also add `origCfg := embeddedBotConfigured` / `embeddedBotConfigured = origCfg` save-and-restore to every existing test that sets `embeddedBot = nil` (search the file for that pattern — there are ~4 such tests). The global must be false in those tests so they don't accidentally pass `configured=true`.

- [ ] **Step 4: Run the new tests — expect them to fail**

```bash
go test ./cmd/dune-admin/ -run 'TestHandleMarketBotStatus_Configured' -v
```

Expected: FAIL — `configured` field absent from the response.

- [ ] **Step 5: Verify the existing `NeitherConfigured` test still compiles with the new defer**

```bash
go test ./cmd/dune-admin/ -run 'TestHandleMarketBotStatus' -v 2>&1 | head -30
```

- [ ] **Step 6: Run all status tests — should be green after Step 2 changes**

```bash
go test ./cmd/dune-admin/ -run 'TestHandleMarketBotStatus' -v
```

Expected: all PASS.

- [ ] **Step 7: Run `make verify`**

```bash
make verify
```

Expected: all checks pass.

- [ ] **Step 8: Commit**

```bash
git add cmd/dune-admin/main.go cmd/dune-admin/handlers_market_bot.go cmd/dune-admin/handlers_market_bot_test.go
git commit -m "feat(marketbot): expose configured field in status API for dormant-mode UI"
```

---

## Task 2 — Frontend: type + button visibility

**Files:**

- Modify: `web/src/api/client.ts` (line 424, `BotStatus` type)
- Modify: `web/src/tabs/MarketTab/index.tsx` (lines 26–33, 75–87)

- [ ] **Step 1: Add `configured` to `BotStatus` type**

In `web/src/api/client.ts` at line 424, add the field:

```ts
export type BotStatus = {
  running: boolean
  mode?: 'embedded' | 'remote' | 'none'
  configured?: boolean   // ← add
  enabled?: boolean
  uptime: string
  // … rest unchanged
}
```

- [ ] **Step 2: Replace `botConnected` with `botConfigured` in MarketTab**

In `web/src/tabs/MarketTab/index.tsx`, replace the state variable and effect:

```ts
// Replace:
const [botConnected, setBotConnected] = useState(false)

useEffect(() => {
  api.marketBot
    .status()
    .then((s) => setBotConnected(s.mode !== 'none'))
    .catch(() => setBotConnected(false))
}, [])

// With:
const [botConfigured, setBotConfigured] = useState(false)

useEffect(() => {
  api.marketBot
    .status()
    // configured field from newer backends; fall back to mode check for older ones
    .then((s) => setBotConfigured(s.configured ?? s.mode !== 'none'))
    .catch(() => setBotConfigured(false))
}, [])
```

Then update the JSX (lines 75–87) — replace `botConnected` with `botConfigured`:

```tsx
{botConfigured
  ? (
      <Button size="sm" variant="ghost" onPress={() => setBotOpen(true)}>
        <Icon name="bot" />
        {' '}
        Bot Control
      </Button>
    )
  : (
      <span className="hidden text-xs text-muted sm:inline">
        No market bot connected — enable the built-in bot to manage it here
      </span>
    )}
```

- [ ] **Step 3: Lint check**

```bash
cd web && pnpm lint
```

Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add web/src/api/client.ts web/src/tabs/MarketTab/index.tsx
git commit -m "feat(marketbot): show Bot Control button whenever bot is configured, not just active"
```

---

## Task 3 — Frontend: BotActions dormant mode

**Files:**

- Modify: `web/src/tabs/MarketTab/bot/BotActions.tsx`

When `status?.mode === 'none'`, the bot is configured but not running. The lifecycle
buttons (Resume, Pause, Reinitialize) must be hidden; Wipe Listings stays active so
recovery is possible. A small hint explains why the controls are absent.

- [ ] **Step 1: Edit BotActions**

Replace the full content of `web/src/tabs/MarketTab/bot/BotActions.tsx`:

```tsx
import { useState } from 'react'
import { Button, Spinner, toast } from '@heroui/react'
import { api } from '../../../api/client'
import type { BotStatus } from '../../../api/client'
import { Icon, ConfirmDialog } from '../../../dune-ui'

type Props = {
  status: BotStatus | null
  onRefresh: () => void
}

type BusyOp = 'start' | 'stop' | 'restart' | 'cleanup'

export default function BotActions({ status, onRefresh }: Props) {
  const [busy, setBusy] = useState<BusyOp | null>(null)
  const [confirmOpen, setConfirmOpen] = useState(false)

  const run = async (cmd: 'start' | 'stop' | 'restart') => {
    setBusy(cmd)
    try {
      const res = await api.marketBot.lifecycle(cmd)
      const actionLabel = cmd === 'start' ? 'resume' : cmd === 'stop' ? 'pause' : 'reinitialize'
      toast.success(`Bot ${actionLabel}: ${res.output || 'ok'}`)
      setTimeout(onRefresh, 1500)
    }
    catch (e: unknown) {
      const actionLabel = cmd === 'start' ? 'resume' : cmd === 'stop' ? 'pause' : 'reinitialize'
      toast.danger(`Failed to ${actionLabel} bot: ${e instanceof Error ? e.message : String(e)}`)
    }
    finally {
      setBusy(null)
    }
  }

  const runCleanup = async () => {
    setConfirmOpen(false)
    setBusy('cleanup')
    try {
      const res = await api.marketBot.cleanup()
      toast.success(`Wiped ${res.orders_deleted} listings (${res.items_deleted} items)`)
      setTimeout(onRefresh, 1500)
    }
    catch (e: unknown) {
      toast.danger(`Cleanup failed: ${e instanceof Error ? e.message : String(e)}`)
    }
    finally {
      setBusy(null)
    }
  }

  const running = status?.running ?? false
  const dormant = status?.mode === 'none'

  return (
    <>
      <div className="flex items-center gap-2 flex-wrap">
        {dormant
          ? (
              <span className="text-xs text-muted">
                Bot disabled — enable in Settings → Market Bot to use lifecycle controls.
              </span>
            )
          : (
              <>
                <Button
                  size="sm"
                  variant="outline"
                  isDisabled={running || busy !== null}
                  onPress={() => run('start')}
                >
                  {busy === 'start' ? <Spinner size="sm" color="current" /> : <Icon name="play" />}
                  Resume
                </Button>
                <Button
                  size="sm"
                  variant="danger-soft"
                  isDisabled={!running || busy !== null}
                  onPress={() => run('stop')}
                >
                  {busy === 'stop' ? <Spinner size="sm" color="current" /> : <Icon name="square" />}
                  Pause
                </Button>
                <Button
                  size="sm"
                  variant="ghost"
                  isDisabled={busy !== null}
                  onPress={() => run('restart')}
                >
                  {busy === 'restart' ? <Spinner size="sm" color="current" /> : <Icon name="refresh-cw" />}
                  Reinitialize
                </Button>
              </>
            )}

        <Button
          size="sm"
          variant="danger-soft"
          isDisabled={busy !== null}
          onPress={() => setConfirmOpen(true)}
        >
          {busy === 'cleanup' ? <Spinner size="sm" color="current" /> : <Icon name="trash-2" />}
          Wipe Listings
        </Button>
      </div>

      <ConfirmDialog
        open={confirmOpen}
        title="Wipe all bot listings?"
        description="This deletes every active Revy listing on the exchange. Player listings, fulfilled-order history, and Revy's Solari balance are untouched. The next list tick will repopulate listings from the catalog."
        confirmLabel="Wipe Listings"
        onConfirm={runCleanup}
        onCancel={() => setConfirmOpen(false)}
      />
    </>
  )
}
```

- [ ] **Step 2: Lint check**

```bash
cd web && pnpm lint
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add web/src/tabs/MarketTab/bot/BotActions.tsx
git commit -m "feat(marketbot): hide lifecycle controls in dormant mode; Wipe Listings always accessible"
```

---

## Task 4 — Settings: remove `market_bot_enabled` toggle

**Files:**

- Modify: `web/src/components/SettingsConfigForm.tsx`

Remove the `CB` (checkbox) for `market_bot_enabled` and its wrapping `<div>`. Replace it
with a text note directing users to the config file. Keep the Remote URL / token fields
and the Paths panel unchanged.

- [ ] **Step 1: Remove the checkbox and update the Mode panel**

In `SettingsConfigForm.tsx`, find the Market Bot Mode panel (around line 396). Replace:

```tsx
<Panel>
  <SectionLabel>Mode</SectionLabel>
  <div className="mt-1">
    <CB
      label="Enable embedded bot"
      checked={cfg.market_bot_enabled}
      onChange={setBool('market_bot_enabled')}
      hint="Runs in-process alongside dune-admin. Toggling off stops it immediately on save."
    />
  </div>
  <G2>
    <F label="Remote URL" hint="forward to standalone bot instead">
      <TI value={cfg.market_bot_remote_url} onChange={set('market_bot_remote_url')} placeholder="http://host:9191" />
    </F>
    <F label="Remote token">
      <TI value={cfg.market_bot_remote_token} onChange={set('market_bot_remote_token')} type="password" placeholder={MASKED} />
    </F>
  </G2>
</Panel>
```

With:

```tsx
<Panel>
  <SectionLabel>Mode</SectionLabel>
  <p className="text-xs text-muted mt-1 mb-3">
    Set <code className="font-mono bg-surface-secondary px-1 rounded">market_bot_enabled: true</code> in{' '}
    <code className="font-mono bg-surface-secondary px-1 rounded">~/.dune-admin/config.yaml</code> to
    run the embedded bot. Runtime pause/resume is in the Bot Control panel on the Market tab.
  </p>
  <G2>
    <F label="Remote URL" hint="forward to standalone bot instead">
      <TI value={cfg.market_bot_remote_url} onChange={set('market_bot_remote_url')} placeholder="http://host:9191" />
    </F>
    <F label="Remote token">
      <TI value={cfg.market_bot_remote_token} onChange={set('market_bot_remote_token')} type="password" placeholder={MASKED} />
    </F>
  </G2>
</Panel>
```

- [ ] **Step 2: Remove `market_bot_enabled` from `EMPTY` and `pointerBoolFields`**

In `EMPTY` (around line 9), remove:

```ts
  market_bot_enabled: false,
```

In `pointerBoolFields` (around line 35), remove `'market_bot_enabled'` from the set:

```ts
// Before:
const pointerBoolFields = new Set<keyof AppConfig>(['amp_use_container', 'market_bot_enabled'])

// After:
const pointerBoolFields = new Set<keyof AppConfig>(['amp_use_container'])
```

- [ ] **Step 3: Lint check**

```bash
cd web && pnpm lint
```

Expected: no errors. TypeScript strict — `AppConfig` still has `market_bot_enabled: boolean` (the Go backend still accepts it), so removing it from the form state and EMPTY might cause a type gap. If `pnpm lint` errors on missing key in `EMPTY`, also remove `market_bot_enabled` from the `AppConfig` type in `web/src/api/client.ts`.

- [ ] **Step 4: Commit**

```bash
git add web/src/components/SettingsConfigForm.tsx
git commit -m "feat(marketbot): remove enabled toggle from Settings; managed via config file + Bot Control panel"
```

---

## Task 5 — Final verification

- [ ] **Step 1: Run full backend tests with race detector**

```bash
make verify
```

Expected: all checks pass, `0 issues`.

- [ ] **Step 2: Start dev server and smoke-test**

```bash
make dev
```

Manual checks (do these in order):

1. With `market_bot_enabled: false` in config → open Market tab → **Bot Control button visible** (was broken before).
2. Click Bot Control → panel opens → lifecycle buttons hidden → Wipe Listings button active.
3. Settings → Market Bot tab → no enable/disable checkbox → explanatory note present.
4. With `market_bot_enabled: true` → open panel → lifecycle buttons show → normal operation.
