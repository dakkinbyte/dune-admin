# Bot Server Config Consolidation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move the five market-bot server-config fields (paths + remote URL/token) from Settings into a new "Server" tab in the Bot Control panel, eliminating the Market Bot tab in Settings entirely.

**Architecture:** New `BotServerConfig.tsx` component loads `AppConfig` via `api.config.get()`, edits five fields, saves back via `api.config.save()`. `BotControlPanel` gets a fourth "Server" tab. Settings loses its entire Market Bot tab and panel — those fields stay in `EMPTY` silently so Settings saves don't blank them out.

**Tech Stack:** React + TypeScript strict, HeroUI v3 (`@heroui/react`), dune-ui wrappers, pnpm.

---

## File Map

| File | Change |
|---|---|
| `web/src/tabs/MarketTab/bot/BotServerConfig.tsx` | Create — loads/saves AppConfig market-bot server fields |
| `web/src/tabs/MarketTab/bot/BotControlPanel.tsx` | Modify — add Server tab + import |
| `web/src/components/SettingsConfigForm.tsx` | Modify — delete Market Bot `Tabs.Tab` and `Tabs.Panel` |

---

## Task 1 — Create BotServerConfig + wire into BotControlPanel

**Files:**

- Create: `web/src/tabs/MarketTab/bot/BotServerConfig.tsx`
- Modify: `web/src/tabs/MarketTab/bot/BotControlPanel.tsx`

- [ ] **Step 1: Create `BotServerConfig.tsx`**

Create `/Volumes/Engineering/Icehunter/dune-admin/web/src/tabs/MarketTab/bot/BotServerConfig.tsx` with this exact content:

```tsx
import { useState, useEffect } from 'react'
import { Button, Spinner, toast } from '@heroui/react'
import { api, MASKED } from '../../../api/client'
import type { AppConfig } from '../../../api/client'
import { Panel, SectionLabel } from '../../../dune-ui'

const inputCls = 'bg-surface border border-border rounded px-2 py-1.5 text-sm text-foreground w-full font-mono placeholder:text-muted/50 focus:outline-none focus:border-accent/60'

export default function BotServerConfig() {
  const [cfg, setCfg] = useState<AppConfig | null>(null)
  const [loading, setLoading] = useState(false)
  const [saving, setSaving] = useState(false)

  useEffect(() => {
    setLoading(true)
    api.config.get()
      .then(setCfg)
      .catch(() => toast.danger('Failed to load server config'))
      .finally(() => setLoading(false))
  }, [])

  const set = (key: keyof AppConfig) => (e: React.ChangeEvent<HTMLInputElement>) =>
    setCfg(prev => prev ? { ...prev, [key]: e.target.value } : prev)

  const save = async () => {
    if (!cfg) return
    setSaving(true)
    try {
      await api.config.save(cfg)
      toast.success('Server config saved — restart required to apply changes')
    }
    catch (e: unknown) {
      toast.danger(`Save failed: ${e instanceof Error ? e.message : String(e)}`)
    }
    finally {
      setSaving(false)
    }
  }

  if (loading) {
    return <div className="flex justify-center py-8"><Spinner size="sm" /></div>
  }
  if (!cfg) {
    return <p className="text-xs text-muted">Config unavailable.</p>
  }

  return (
    <div className="flex flex-col gap-4">
      <Panel>
        <SectionLabel>Embedded Bot</SectionLabel>
        <div className="mt-2 grid grid-cols-1 gap-3 sm:grid-cols-2">
          <label className="flex flex-col gap-1">
            <span className="text-xs font-medium text-muted">Cache DB</span>
            <input className={inputCls} value={cfg.market_bot_cache_db} onChange={set('market_bot_cache_db')} placeholder="~/.dune-admin/market-bot-cache.db" />
          </label>
          <label className="flex flex-col gap-1">
            <span className="text-xs font-medium text-muted">Item data</span>
            <input className={inputCls} value={cfg.market_bot_item_data} onChange={set('market_bot_item_data')} placeholder="item-data.json" />
          </label>
          <label className="flex flex-col gap-1 sm:col-span-2">
            <span className="text-xs font-medium text-muted">State path</span>
            <input className={inputCls} value={cfg.market_bot_state} onChange={set('market_bot_state')} placeholder="~/.dune-admin/market-bot-state.json" />
          </label>
        </div>
      </Panel>

      <Panel>
        <SectionLabel>Remote Bot</SectionLabel>
        <div className="mt-2 grid grid-cols-1 gap-3 sm:grid-cols-2">
          <label className="flex flex-col gap-1">
            <span className="text-xs font-medium text-muted">Remote URL</span>
            <input className={inputCls} value={cfg.market_bot_remote_url} onChange={set('market_bot_remote_url')} placeholder="http://host:9191" />
          </label>
          <label className="flex flex-col gap-1">
            <span className="text-xs font-medium text-muted">Remote token</span>
            <input className={inputCls} type="password" value={cfg.market_bot_remote_token} onChange={set('market_bot_remote_token')} placeholder={MASKED} />
          </label>
        </div>
      </Panel>

      <div className="flex items-center justify-between gap-4">
        <p className="text-xs text-muted">Changes require a server restart to take effect.</p>
        <Button size="sm" onPress={save} isDisabled={saving}>
          {saving ? <Spinner size="sm" color="current" /> : null}
          Save
        </Button>
      </div>
    </div>
  )
}
```

- [ ] **Step 2: Add the Server tab to BotControlPanel**

In `web/src/tabs/MarketTab/bot/BotControlPanel.tsx`:

Add import after the `DisabledItemsManager` import line:

```tsx
import BotServerConfig from './BotServerConfig'
```

In the `Tabs.List`, add the Server tab between Disabled Items and Logs:

```tsx
<Tabs.Tab id="server">
  Server
  <Tabs.Indicator />
</Tabs.Tab>
```

After the `Tabs.Panel id="disabled"` closing tag and before `Tabs.Panel id="logs"`, add:

```tsx
<Tabs.Panel id="server" className="pt-4 overflow-y-auto flex-1 pr-1">
  <BotServerConfig />
</Tabs.Panel>
```

- [ ] **Step 3: Lint**

```bash
cd /Volumes/Engineering/Icehunter/dune-admin/web && pnpm lint
```

Expected: no errors.

- [ ] **Step 4: Commit**

```bash
cd /Volumes/Engineering/Icehunter/dune-admin
git add web/src/tabs/MarketTab/bot/BotServerConfig.tsx web/src/tabs/MarketTab/bot/BotControlPanel.tsx
git commit -m "feat(marketbot): add Server tab to Bot Control panel with restart-required config fields"
```

---

## Task 2 — Remove Market Bot tab from Settings

**Files:**

- Modify: `web/src/components/SettingsConfigForm.tsx`

The Market Bot tab and panel must be deleted entirely. The five `market_bot_*` fields
**must remain in `EMPTY`** — Settings saves the full `AppConfig` and the hidden fields
preserve their real values rather than being blanked.

- [ ] **Step 1: Remove the `Tabs.Tab` for marketbot**

In `web/src/components/SettingsConfigForm.tsx`, find and delete this block (around line 221):

```tsx
            <Tabs.Tab id="marketbot">
              Market Bot
              <Tabs.Indicator />
            </Tabs.Tab>
```

- [ ] **Step 2: Remove the `Tabs.Panel` for marketbot**

Find and delete the entire panel block (around line 395–427). It starts with:

```tsx
        {/* ── Market Bot ─────────────────────────────────────────────────── */}
        <Tabs.Panel id="marketbot" className="pt-4 overflow-y-auto flex-1 pr-1 flex flex-col gap-4">
```

and ends with the matching `</Tabs.Panel>`. Delete everything inclusive.

- [ ] **Step 3: Lint**

```bash
cd /Volumes/Engineering/Icehunter/dune-admin/web && pnpm lint
```

Expected: no errors. If TypeScript complains about unused imports (e.g. a field name that only appeared in the panel), remove those too.

- [ ] **Step 4: Commit**

```bash
cd /Volumes/Engineering/Icehunter/dune-admin
git add web/src/components/SettingsConfigForm.tsx
git commit -m "feat(marketbot): remove Market Bot tab from Settings — fully consolidated in Bot Control panel"
```

---

## Task 3 — Final verification

- [ ] **Step 1: Full lint + type check**

```bash
cd /Volumes/Engineering/Icehunter/dune-admin/web && pnpm lint
```

Expected: zero errors, zero warnings.

- [ ] **Step 2: Backend verify (ensure no Go regressions)**

```bash
cd /Volumes/Engineering/Icehunter/dune-admin && make verify
```

Expected: all checks pass.

- [ ] **Step 3: Manual smoke test**

Start dev server (`make dev` from the project root). Check:

1. Settings → no "Market Bot" tab in the tab list.
2. Market tab → Bot Control → Server tab exists and loads the five fields.
3. Edit Cache DB path → Save → success toast with "restart required".
4. Close and reopen Server tab → saved value persists (confirms round-trip through the API).
