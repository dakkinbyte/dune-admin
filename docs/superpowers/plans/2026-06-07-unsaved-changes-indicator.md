# Unsaved Changes Indicator Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an unsaved-changes banner and diff status counts (X added · Y updated · Z removed) to ManagePacksModal and WelcomePackageTab so users know when changes exist that haven't been saved to the server.

**Architecture:** Each UI tracks a `savedSnapshot` — what's on the server — initialized on load and updated after a successful save. A `useMemo` diff compares current in-memory state against the snapshot to produce counts. The banner and status counts are conditional on `isDirty`. No new files; all changes are in existing components.

**Tech Stack:** React, TypeScript, HeroUI v3 (`@heroui/react`), `dune-ui` Icon component

---

## Files Modified

| File | Change |
|------|--------|
| `web/src/tabs/WelcomePackageTab/types.ts` | Add `WelcomeConfigDiff` type; add `configDiff` to `WelcomeSharedProps` |
| `web/src/tabs/WelcomePackageTab/index.tsx` | Add `savedConfig` state + `configDiff` useMemo; update `load`/`save` to snapshot; pass diff to views |
| `web/src/tabs/WelcomePackageTab/views/ConfigView.tsx` | Add `configDiff` to props Pick; render banner + status counts |
| `web/src/tabs/WelcomePackageTab/views/PackagesView.tsx` | Add `configDiff` to props Pick; render banner + status counts |
| `web/src/tabs/PlayersTab/modals/ManagePacksModal.tsx` | Add `savedPacks` state + `packDiff` useMemo; update `loadPacks`/`save` to snapshot; render banner + status counts |

---

## Task 1: Add `WelcomeConfigDiff` to shared types

**Files:**

- Modify: `web/src/tabs/WelcomePackageTab/types.ts`

- [ ] **Step 1: Add the diff type and update WelcomeSharedProps**

Replace the contents of `web/src/tabs/WelcomePackageTab/types.ts` with:

```ts
import type { WelcomePackage, WelcomeGrantRecord, WelcomePackageItem } from '../../api/client'

export type WelcomeSection = 'config' | 'packages' | 'grants'

export interface WelcomeConfigDiff {
  packageAdded: number
  packageRemoved: number
  packageUpdated: number
  settingsChanged: boolean
  isDirty: boolean
}

export interface WelcomeSharedProps {
  // config state
  enabled: boolean
  setEnabled: (v: boolean) => void
  scanSecs: number
  setScanSecs: (v: number) => void
  packages: WelcomePackage[]
  setPackages: (ps: WelcomePackage[]) => void
  activeVersions: string[]
  setActiveVersions: (avs: string[] | ((prev: string[]) => string[])) => void
  // message state
  welcomeMessageEnabled: boolean
  setWelcomeMessageEnabled: (v: boolean) => void
  welcomeMessage: string
  setWelcomeMessage: (v: string) => void
  welcomeWhisperSourcePlayer: string
  setWelcomeWhisperSourcePlayer: (v: string) => void
  // actions
  save: () => Promise<void>
  runNow: () => Promise<void>
  saving: boolean
  running: boolean
  load: () => void
  loading: boolean
  // grants
  grants: WelcomeGrantRecord[]
  retry: (g: WelcomeGrantRecord) => Promise<void>
  // templates (packages view)
  templates: { id: string, name: string }[]
  // unsaved-changes diff
  configDiff: WelcomeConfigDiff
}

export type { WelcomePackageItem }
```

- [ ] **Step 2: Verify TypeScript compiles**

```bash
cd /Volumes/Engineering/Icehunter/dune-admin/web && pnpm build 2>&1 | head -40
```

Expected: errors about `configDiff` missing where views are instantiated (in `index.tsx`) — these are expected and resolved in Task 2.

- [ ] **Step 3: Commit**

```bash
git add web/src/tabs/WelcomePackageTab/types.ts
git commit -m "feat(welcome): add WelcomeConfigDiff type to shared props"
```

---

## Task 2: Wire saved-config snapshot and diff in WelcomePackageTab/index.tsx

**Files:**

- Modify: `web/src/tabs/WelcomePackageTab/index.tsx`

- [ ] **Step 1: Add `savedConfig` state, `configDiff` useMemo, update load/save**

Replace the full contents of `web/src/tabs/WelcomePackageTab/index.tsx` with:

```tsx
import type React from 'react'
import { useState, useEffect, useCallback, useMemo } from 'react'
import { toast } from '@heroui/react'
import { useTranslation } from 'react-i18next'
import { api } from '../../api/client'
import type { WelcomePackage, WelcomePackageConfig, WelcomeGrantRecord } from '../../api/client'
import { SideNav } from '../../dune-ui'
import type { WelcomeSection, WelcomeConfigDiff } from './types'
import { ConfigView } from './views/ConfigView'
import { PackagesView } from './views/PackagesView'
import { GrantsView } from './views/GrantsView'

type WelcomePackageTabProps
  = | { showSubnav?: false, section?: WelcomeSection, onSectionChange?: never }
    | { showSubnav: true, section?: WelcomeSection, onSectionChange: (s: WelcomeSection) => void }

export const WelcomePackageTab: React.FC<WelcomePackageTabProps> = ({ showSubnav, section = 'config', onSectionChange }: WelcomePackageTabProps) => {
  const { t } = useTranslation()

  const SECTIONS: { key: WelcomeSection, label: string }[] = [
    { key: 'config', label: t('welcome.sections.config') },
    { key: 'packages', label: t('welcome.sections.packages') },
    { key: 'grants', label: t('welcome.sections.grants') },
  ]

  const [grants, setGrants] = useState<WelcomeGrantRecord[]>([])
  const [loading, setLoading] = useState(false)
  const [saving, setSaving] = useState(false)
  const [running, setRunning] = useState(false)

  const [enabled, setEnabled] = useState(false)
  const [scanSecs, setScanSecs] = useState(30)
  const [packages, setPackages] = useState<WelcomePackage[]>([])
  const [activeVersions, setActiveVersions] = useState<string[]>([])
  const [welcomeMessageEnabled, setWelcomeMessageEnabled] = useState(false)
  const [welcomeMessage, setWelcomeMessage] = useState('')
  const [welcomeWhisperSourcePlayer, setWelcomeWhisperSourcePlayer] = useState('')
  const [templates, setTemplates] = useState<{ id: string, name: string }[]>([])

  // Snapshot of what's persisted on the server; null until first load completes.
  const [savedConfig, setSavedConfig] = useState<WelcomePackageConfig | null>(null)

  const applyConfig = useCallback((c: WelcomePackageConfig) => {
    setEnabled(c.enabled)
    setScanSecs(c.scan_interval_secs)
    setPackages(c.packages ?? [])
    const avs = c.active_versions?.length
      ? c.active_versions
      : c.active_version ? [c.active_version] : []
    setActiveVersions(avs)
    setWelcomeMessageEnabled(c.welcome_message_enabled ?? false)
    setWelcomeMessage(c.welcome_message ?? '')
    setWelcomeWhisperSourcePlayer(c.welcome_whisper_source_player ?? '')
  }, [])

  const load = useCallback(() => {
    Promise.resolve()
      .then(() => setLoading(true))
      .then(() => api.welcomePackage.config())
      .then((c) => { applyConfig(c); setSavedConfig(c) })
      .then(() => api.welcomePackage.grants(100))
      .then(setGrants)
      .catch((e: unknown) => {
        const msg = e instanceof Error ? e.message : String(e)
        toast.danger(t('welcome.failedToLoad', { message: msg }))
      })
      .finally(() => setLoading(false))
  }, [t, applyConfig])

  useEffect(() => {
    load()
  }, [load])

  useEffect(() => {
    api.players.templates().then(setTemplates).catch(() => {})
  }, [])

  const save = async () => {
    setSaving(true)
    try {
      const cfg: WelcomePackageConfig = {
        enabled,
        scan_interval_secs: scanSecs,
        active_version: activeVersions[0] ?? '',
        active_versions: activeVersions,
        packages,
        welcome_message_enabled: welcomeMessageEnabled,
        welcome_message: welcomeMessage,
        welcome_whisper_source_player: welcomeWhisperSourcePlayer,
      }
      const saved = await api.welcomePackage.saveConfig(cfg)
      applyConfig(saved)
      setSavedConfig(saved)
      toast.success(enabled
        ? t('welcome.savedEnabled', { version: activeVersions.join(', ') })
        : t('welcome.savedDisabled'))
    }
    catch (e) {
      toast.danger(t('welcome.saveFailed', { message: e instanceof Error ? e.message : String(e) }))
    }
    finally {
      setSaving(false)
    }
  }

  const runNow = async () => {
    setRunning(true)
    try {
      const r = await api.welcomePackage.run()
      toast.success(t('welcome.scanComplete', { granted: r.granted, failed: r.failed, skipped: r.skipped }))
      setGrants(await api.welcomePackage.grants(100))
    }
    catch (e) {
      toast.danger(t('welcome.runFailed', { message: e instanceof Error ? e.message : String(e) }))
    }
    finally {
      setRunning(false)
    }
  }

  const retry = async (g: WelcomeGrantRecord) => {
    try {
      await api.welcomePackage.retry(g.fls_id, g.package_version, g.account_id)
      toast.success(t('welcome.retryCleared'))
      setGrants(await api.welcomePackage.grants(100))
    }
    catch (e) {
      toast.danger(t('welcome.retryFailed', { message: e instanceof Error ? e.message : String(e) }))
    }
  }

  const configDiff = useMemo((): WelcomeConfigDiff => {
    if (!savedConfig) {
      return { packageAdded: 0, packageRemoved: 0, packageUpdated: 0, settingsChanged: false, isDirty: false }
    }
    const savedPkgs = savedConfig.packages ?? []
    const savedPkgMap = new Map(savedPkgs.map((p) => [p.version, p]))
    const currentPkgIds = new Set(packages.map((p) => p.version))

    const packageAdded = packages.filter((p) => !savedPkgMap.has(p.version)).length
    const packageRemoved = savedPkgs.filter((p) => !currentPkgIds.has(p.version)).length
    const packageUpdated = packages.filter((p) => {
      if (!savedPkgMap.has(p.version)) return false
      return JSON.stringify(p) !== JSON.stringify(savedPkgMap.get(p.version))
    }).length

    const settingsChanged =
      enabled !== savedConfig.enabled
      || scanSecs !== savedConfig.scan_interval_secs
      || JSON.stringify([...activeVersions].sort()) !== JSON.stringify([...(savedConfig.active_versions ?? [])].sort())
      || welcomeMessageEnabled !== (savedConfig.welcome_message_enabled ?? false)
      || welcomeMessage !== (savedConfig.welcome_message ?? '')
      || welcomeWhisperSourcePlayer !== (savedConfig.welcome_whisper_source_player ?? '')

    const isDirty = packageAdded + packageRemoved + packageUpdated > 0 || settingsChanged
    return { packageAdded, packageRemoved, packageUpdated, settingsChanged, isDirty }
  }, [packages, enabled, scanSecs, activeVersions, welcomeMessageEnabled, welcomeMessage, welcomeWhisperSourcePlayer, savedConfig])

  const activeView = () => {
    switch (section) {
      case 'config':
        return (
          <ConfigView
            enabled={enabled}
            setEnabled={setEnabled}
            scanSecs={scanSecs}
            setScanSecs={setScanSecs}
            packages={packages}
            activeVersions={activeVersions}
            setActiveVersions={setActiveVersions}
            welcomeMessageEnabled={welcomeMessageEnabled}
            setWelcomeMessageEnabled={setWelcomeMessageEnabled}
            welcomeMessage={welcomeMessage}
            setWelcomeMessage={setWelcomeMessage}
            welcomeWhisperSourcePlayer={welcomeWhisperSourcePlayer}
            setWelcomeWhisperSourcePlayer={setWelcomeWhisperSourcePlayer}
            save={save}
            saving={saving}
            runNow={runNow}
            running={running}
            load={load}
            loading={loading}
            configDiff={configDiff}
          />
        )
      case 'packages':
        return (
          <PackagesView
            packages={packages}
            setPackages={setPackages}
            activeVersions={activeVersions}
            templates={templates}
            save={save}
            saving={saving}
            load={load}
            loading={loading}
            configDiff={configDiff}
          />
        )
      case 'grants':
        return <GrantsView grants={grants} retry={retry} load={load} loading={loading} />
    }
  }

  if (showSubnav) {
    return (
      <div className="h-full min-h-0 flex gap-3">
        <SideNav
          title={t('welcome.title')}
          items={SECTIONS}
          active={section}
          onSelect={(k) => onSectionChange?.(k as WelcomeSection)}
        />
        <div className="flex-1 min-h-0 flex flex-col">
          {activeView()}
        </div>
      </div>
    )
  }

  return (
    <div className="flex flex-col h-full min-h-0">
      {activeView()}
    </div>
  )
}
```

- [ ] **Step 2: Verify TypeScript compiles**

```bash
cd /Volumes/Engineering/Icehunter/dune-admin/web && pnpm build 2>&1 | head -40
```

Expected: errors about `configDiff` missing from ConfigView/PackagesView prop types — resolved in Tasks 3 and 4.

- [ ] **Step 3: Commit**

```bash
git add web/src/tabs/WelcomePackageTab/index.tsx
git commit -m "feat(welcome): track saved-config snapshot and compute unsaved-changes diff"
```

---

## Task 3: Add banner + status counts to ConfigView

**Files:**

- Modify: `web/src/tabs/WelcomePackageTab/views/ConfigView.tsx`

- [ ] **Step 1: Update ConfigView with banner and status counts**

Replace the full contents of `web/src/tabs/WelcomePackageTab/views/ConfigView.tsx` with:

```tsx
import type React from 'react'
import { Button, ListBox, Spinner } from '@heroui/react'
import { useTranslation } from 'react-i18next'
import { Icon, NumberInput, PageHeader, Panel, SectionLabel } from '../../../dune-ui'
import type { WelcomeSharedProps, WelcomeConfigDiff } from '../types'

type ConfigViewProps = Pick<
  WelcomeSharedProps,
  | 'enabled' | 'setEnabled'
  | 'scanSecs' | 'setScanSecs'
  | 'packages'
  | 'activeVersions' | 'setActiveVersions'
  | 'welcomeMessageEnabled' | 'setWelcomeMessageEnabled'
  | 'welcomeMessage' | 'setWelcomeMessage'
  | 'welcomeWhisperSourcePlayer' | 'setWelcomeWhisperSourcePlayer'
  | 'save' | 'saving'
  | 'runNow' | 'running'
  | 'load' | 'loading'
  | 'configDiff'
>

function DiffStatus({ diff }: { diff: WelcomeConfigDiff }) {
  const parts: { key: string, text: string, cls: string }[] = []
  if (diff.settingsChanged) parts.push({ key: 'settings', text: 'settings changed', cls: 'text-warning' })
  if (diff.packageAdded > 0) parts.push({ key: 'added', text: `${diff.packageAdded} added`, cls: 'text-success' })
  if (diff.packageUpdated > 0) parts.push({ key: 'updated', text: `${diff.packageUpdated} updated`, cls: 'text-warning' })
  if (diff.packageRemoved > 0) parts.push({ key: 'removed', text: `${diff.packageRemoved} removed`, cls: 'text-danger' })
  if (parts.length === 0) return null
  return (
    <span className="text-xs flex items-center gap-1">
      {parts.map((p, i) => (
        <span key={p.key} className="flex items-center gap-1">
          {i > 0 && <span className="text-muted">·</span>}
          <span className={p.cls}>{p.text}</span>
        </span>
      ))}
    </span>
  )
}

export const ConfigView: React.FC<ConfigViewProps> = ({
  enabled, setEnabled,
  scanSecs, setScanSecs,
  packages,
  activeVersions, setActiveVersions,
  welcomeMessageEnabled, setWelcomeMessageEnabled,
  welcomeMessage, setWelcomeMessage,
  welcomeWhisperSourcePlayer, setWelcomeWhisperSourcePlayer,
  save, saving,
  runNow, running,
  load, loading,
  configDiff,
}) => {
  const { t } = useTranslation()

  return (
    <div className="flex flex-col h-full min-h-0 gap-3">
      {/* Header */}
      <PageHeader title={t('welcome.sections.config')} subtitle={t('welcome.configSubtitle')}>
        <Button size="sm" variant="ghost" onPress={load} isDisabled={loading}>
          {loading
            ? <Spinner size="sm" color="current" />
            : (
                <>
                  <Icon name="refresh-cw" />
                  {' '}
                  {t('common.refresh')}
                </>
              )}
        </Button>
      </PageHeader>

      {/* Unsaved changes banner */}
      {configDiff.isDirty && (
        <div className="shrink-0 rounded-[var(--radius)] px-4 py-2 text-xs font-medium bg-warning/10 border border-warning/40 text-warning flex items-center gap-2">
          <Icon name="triangle-alert" />
          <span>You have unsaved changes — click Save Config to persist them.</span>
        </div>
      )}

      {/* Compact one-liner: enabled toggle + scan interval */}
      <div className="flex items-center gap-6 shrink-0">
        <label className="flex items-center gap-2 cursor-pointer select-none">
          <input
            type="checkbox"
            checked={enabled}
            onChange={(e) => setEnabled(e.target.checked)}
            className="h-4 w-4 accent-accent"
          />
          <span className="text-sm text-foreground">{t('welcome.enabledLabel')}</span>
        </label>
        <span className="text-xs text-muted">{t('welcome.enabledHint')}</span>
        <NumberInput
          label={t('welcome.scanInterval')}
          min={5}
          step={5}
          value={scanSecs}
          onChange={setScanSecs}
          className="w-56 ml-auto"
        />
      </div>

      {/* Active versions — flex-1 fills remaining space */}
      <div className="flex flex-col flex-1 min-h-0 gap-1">
        <SectionLabel>{t('welcome.activeVersionGranted')}</SectionLabel>
        {packages.length === 0
          ? <p className="text-xs text-muted mt-1">{t('welcome.noPackageSelected')}</p>
          : (
              <ListBox
                aria-label={t('welcome.activeVersionGranted')}
                selectionMode="multiple"
                selectedKeys={new Set(activeVersions)}
                onSelectionChange={(keys) => {
                  setActiveVersions(Array.from(keys).map(String))
                }}
                className="flex-1 min-h-0 overflow-y-auto rounded-[var(--radius)] border border-border"
              >
                {packages.map((p) => (
                  <ListBox.Item key={p.version} id={p.version} textValue={p.version}>
                    {p.version}
                    <ListBox.ItemIndicator />
                  </ListBox.Item>
                ))}
              </ListBox>
            )}
      </div>

      {/* Welcome message panel — fixed height */}
      <Panel className="shrink-0">
        <SectionLabel>{t('welcome.message.title')}</SectionLabel>

        <label className="flex items-center gap-2 mt-1 cursor-pointer select-none w-fit">
          <input
            type="checkbox"
            checked={welcomeMessageEnabled}
            onChange={(e) => setWelcomeMessageEnabled(e.target.checked)}
            className="h-4 w-4 accent-accent"
          />
          <span className="text-sm text-foreground">{t('welcome.message.enabledLabel')}</span>
        </label>
        <p className="text-xs text-muted mt-1 mb-3">
          {t('welcome.message.enabledHint')}
        </p>

        <div className="flex flex-col gap-3">
          <div className="flex flex-col gap-1">
            <span className="text-xs text-muted">{t('welcome.message.messageLabel')}</span>
            <textarea
              className="w-full rounded-[var(--radius)] border border-border bg-surface text-foreground text-sm px-3 py-2 resize-none focus:outline-none focus:border-accent disabled:opacity-50"
              rows={3}
              placeholder={t('welcome.message.messagePlaceholder')}
              value={welcomeMessage}
              disabled={!welcomeMessageEnabled}
              onChange={(e) => setWelcomeMessage(e.target.value)}
            />
          </div>
          <div className="flex flex-col gap-1 max-w-md">
            <span className="text-xs text-muted">{t('welcome.message.senderLabel')}</span>
            <input
              className="w-full rounded-[var(--radius)] border border-border bg-surface text-foreground text-sm px-3 py-2 focus:outline-none focus:border-accent disabled:opacity-50"
              placeholder={t('welcome.message.senderPlaceholder')}
              value={welcomeWhisperSourcePlayer}
              disabled={!welcomeMessageEnabled}
              onChange={(e) => setWelcomeWhisperSourcePlayer(e.target.value)}
            />
          </div>
        </div>
      </Panel>

      {/* Action bar — fixed at bottom */}
      <div className="flex items-center gap-3 shrink-0">
        <Button size="sm" variant="secondary" onPress={save} isDisabled={saving}>
          {saving
            ? <Spinner size="sm" color="current" />
            : (
                <>
                  <Icon name="save" />
                  {' '}
                  {t('welcome.saveConfig')}
                </>
              )}
        </Button>
        <Button size="sm" variant="outline" onPress={runNow} isDisabled={running}>
          {running
            ? <Spinner size="sm" color="current" />
            : (
                <>
                  <Icon name="play" />
                  {' '}
                  {t('welcome.runNow')}
                </>
              )}
        </Button>
        <DiffStatus diff={configDiff} />
      </div>
    </div>
  )
}
```

- [ ] **Step 2: Verify TypeScript compiles**

```bash
cd /Volumes/Engineering/Icehunter/dune-admin/web && pnpm build 2>&1 | head -40
```

Expected: ConfigView compiles cleanly; still one error from PackagesView missing `configDiff` (resolved in Task 4).

- [ ] **Step 3: Commit**

```bash
git add web/src/tabs/WelcomePackageTab/views/ConfigView.tsx
git commit -m "feat(welcome): add unsaved-changes banner and diff status to ConfigView"
```

---

## Task 4: Add banner + status counts to PackagesView

**Files:**

- Modify: `web/src/tabs/WelcomePackageTab/views/PackagesView.tsx`

- [ ] **Step 1: Update PackagesView with banner and status counts**

Replace the full contents of `web/src/tabs/WelcomePackageTab/views/PackagesView.tsx` with:

```tsx
import type React from 'react'
import { useMemo, useState } from 'react'
import { Button, ListBox, SearchField, Select, Spinner } from '@heroui/react'
import { useTranslation } from 'react-i18next'
import { Icon, NumberInput, PageHeader } from '../../../dune-ui'
import type { WelcomeSharedProps, WelcomeConfigDiff, WelcomePackageItem } from '../types'
import type { WelcomePackage } from '../../../api/client'

type PackagesViewProps = Pick<
  WelcomeSharedProps,
  'packages' | 'setPackages' | 'activeVersions' | 'templates' | 'save' | 'saving' | 'load' | 'loading' | 'configDiff'
>

function DiffStatus({ diff }: { diff: WelcomeConfigDiff }) {
  const parts: { key: string, text: string, cls: string }[] = []
  if (diff.settingsChanged) parts.push({ key: 'settings', text: 'settings changed', cls: 'text-warning' })
  if (diff.packageAdded > 0) parts.push({ key: 'added', text: `${diff.packageAdded} added`, cls: 'text-success' })
  if (diff.packageUpdated > 0) parts.push({ key: 'updated', text: `${diff.packageUpdated} updated`, cls: 'text-warning' })
  if (diff.packageRemoved > 0) parts.push({ key: 'removed', text: `${diff.packageRemoved} removed`, cls: 'text-danger' })
  if (parts.length === 0) return null
  return (
    <span className="text-xs flex items-center gap-1">
      {parts.map((p, i) => (
        <span key={p.key} className="flex items-center gap-1">
          {i > 0 && <span className="text-muted">·</span>}
          <span className={p.cls}>{p.text}</span>
        </span>
      ))}
    </span>
  )
}

export const PackagesView: React.FC<PackagesViewProps> = ({
  packages,
  setPackages,
  activeVersions,
  templates,
  save,
  saving,
  load,
  loading,
  configDiff,
}) => {
  const { t } = useTranslation()

  const [selected, setSelected] = useState(() => packages[0]?.version ?? '')
  const [newName, setNewName] = useState('')
  const [addQuery, setAddQuery] = useState('')
  const [addSelected, setAddSelected] = useState('')
  const [addQty, setAddQty] = useState(1)
  const [addQuality, setAddQuality] = useState(0)

  const selectedPkg = packages.find((p) => p.version === selected)
  const items: WelcomePackageItem[] = selectedPkg?.items ?? []

  const setItems = (next: WelcomePackageItem[]) => {
    setPackages(packages.map((p) => (p.version === selected ? { ...p, items: next } : p)))
  }

  const nameMap = useMemo(() => new Map(templates.map((t) => [t.id, t.name])), [templates])

  const addFiltered = useMemo(() => {
    if (!addQuery) return []
    const q = addQuery.toLowerCase()
    return templates
      .filter((tpl) => tpl.id.toLowerCase().includes(q) || tpl.name.toLowerCase().includes(q))
      .slice(0, 100)
  }, [templates, addQuery])

  const pickTemplate = (tpl: { id: string, name: string }) => {
    setAddSelected(tpl.id)
    setAddQuery(tpl.name ? `${tpl.id}  —  ${tpl.name}` : tpl.id)
  }

  const addItem = () => {
    if (!addSelected) return
    setItems([...items, { template: addSelected, qty: addQty, quality: addQuality }])
    setAddQuery('')
    setAddSelected('')
    setAddQty(1)
    setAddQuality(0)
  }

  const removeItem = (i: number) => setItems(items.filter((_, idx) => idx !== i))
  const setItem = (i: number, patch: Partial<WelcomePackageItem>) =>
    setItems(items.map((it, idx) => (idx === i ? { ...it, ...patch } : it)))

  const addVersion = () => {
    const name = newName.trim()
    if (!name || packages.some((p) => p.version === name)) return
    const next: WelcomePackage[] = [...packages, { version: name, items: [] }]
    setPackages(next)
    setSelected(name)
    setNewName('')
  }

  const deleteVersion = (v: string) => {
    const next = packages.filter((p) => p.version !== v)
    setPackages(next)
    if (selected === v) setSelected(next[0]?.version ?? '')
  }

  return (
    <div className="flex flex-col h-full min-h-0">
      <PageHeader title={t('welcome.sections.packages')} subtitle={t('welcome.packagesSubtitle')}>
        <Button size="sm" variant="ghost" onPress={load} isDisabled={loading}>
          {loading
            ? <Spinner size="sm" color="current" />
            : (
                <>
                  <Icon name="refresh-cw" />
                  {' '}
                  {t('common.refresh')}
                </>
              )}
        </Button>
      </PageHeader>

      {/* Unsaved changes banner */}
      {configDiff.isDirty && (
        <div className="shrink-0 rounded-[var(--radius)] mb-3 px-4 py-2 text-xs font-medium bg-warning/10 border border-warning/40 text-warning flex items-center gap-2">
          <Icon name="triangle-alert" />
          <span>You have unsaved changes — click Save Config to persist them.</span>
        </div>
      )}

      {/* Fixed: version picker + new version input */}
      <div className="flex flex-wrap items-end gap-3 pb-3 shrink-0">
        <div className="flex items-end gap-2">
          <div className="flex flex-col gap-0.5">
            <label className="text-xs text-muted">{t('welcome.editingVersion')}</label>
            <Select
              aria-label={t('welcome.editingVersion')}
              selectedKey={selected || null}
              onSelectionChange={(k) => setSelected(k ? String(k) : '')}
              className="w-48"
            >
              <Select.Trigger>
                <Select.Value>
                  {!selected
                    ? '— select —'
                    : selected + (activeVersions.includes(selected) ? ' (active)' : '')}
                </Select.Value>
                <Select.Indicator />
              </Select.Trigger>
              <Select.Popover>
                <ListBox>
                  <ListBox.Item key="_none" id="" textValue="— select —">
                    — select —
                    <ListBox.ItemIndicator />
                  </ListBox.Item>
                  {packages.map((p) => (
                    <ListBox.Item key={p.version} id={p.version} textValue={p.version}>
                      {p.version}
                      {activeVersions.includes(p.version) ? ' (active)' : ''}
                      <ListBox.ItemIndicator />
                    </ListBox.Item>
                  ))}
                </ListBox>
              </Select.Popover>
            </Select>
          </div>
          {selected && (
            <Button size="sm" variant="ghost" onPress={() => deleteVersion(selected)}>
              <Icon name="trash-2" />
            </Button>
          )}
        </div>

        <div className="flex items-end gap-2">
          <div className="flex flex-col gap-0.5">
            <label className="text-xs text-muted">{t('welcome.newVersionLabel')}</label>
            <input
              className="bg-surface border border-border rounded px-2 py-1.5 text-sm text-foreground w-36"
              placeholder={t('welcome.newVersionPlaceholder')}
              value={newName}
              onChange={(e) => setNewName(e.target.value)}
              onKeyDown={(e) => { if (e.key === 'Enter') addVersion() }}
            />
          </div>
          <Button size="sm" variant="outline" onPress={addVersion}>
            <Icon name="plus" />
            {' '}
            {t('welcome.addVersion')}
          </Button>
        </div>
      </div>

      {/* Fixed: add-item row */}
      {selected && (
        <div className="flex items-center gap-2 pb-3 shrink-0">
          <div className="relative flex-1">
            <SearchField
              value={addQuery}
              onChange={(v) => {
                setAddQuery(v)
                setAddSelected('')
              }}
              className="w-full"
            >
              <SearchField.Group>
                <SearchField.SearchIcon />
                <SearchField.Input placeholder="Search item templates…" />
                <SearchField.ClearButton />
              </SearchField.Group>
            </SearchField>
            {addFiltered.length > 0 && (
              <div className="absolute z-50 w-full mt-1 rounded-[var(--radius)] border border-border bg-surface overflow-y-auto max-h-52">
                {addFiltered.map((tpl) => (
                  <div
                    key={tpl.id}
                    className="px-3 py-1.5 text-xs cursor-pointer hover:bg-surface-hover"
                    onClick={() => pickTemplate(tpl)}
                  >
                    <span className="font-mono">{tpl.id}</span>
                    {tpl.name
                      ? (
                          <span className="text-muted">
                            {' — '}
                            {tpl.name}
                          </span>
                        )
                      : null}
                  </div>
                ))}
              </div>
            )}
          </div>
          <NumberInput prefix="Qty" ariaLabel="Qty" min={1} value={addQty} onChange={setAddQty} className="w-48 shrink-0" />
          <NumberInput prefix="Quality" ariaLabel="Quality" min={0} value={addQuality} onChange={setAddQuality} className="w-48 shrink-0" />
          <Button size="sm" onPress={addItem} isDisabled={!addSelected} className="shrink-0">
            <Icon name="plus" />
            {' '}
            {t('welcome.addItem')}
          </Button>
        </div>
      )}

      {/* Scrollable: item list */}
      <div className="flex-1 min-h-0 overflow-y-auto flex flex-col gap-1.5 pr-1">
        {!selected
          ? <p className="text-xs text-muted">{t('welcome.noPackageSelected')}</p>
          : items.length === 0
            ? <p className="text-xs text-muted">{t('welcome.noItemsYet')}</p>
            : items.map((it, i) => (
                <div
                  key={i}
                  className="flex items-center gap-2 px-3 py-1.5 rounded-[var(--radius)] text-xs bg-surface border border-border"
                >
                  <div className="flex-1 min-w-0 leading-tight">
                    <div className="truncate text-foreground">{nameMap.get(it.template) || it.template}</div>
                    {nameMap.get(it.template) && (
                      <div className="font-mono text-[10px] text-muted truncate">{it.template}</div>
                    )}
                  </div>
                  <NumberInput ariaLabel="Qty" prefix="Qty" min={1} value={it.qty} onChange={(v) => setItem(i, { qty: v })} className="w-48 shrink-0" />
                  <NumberInput ariaLabel="Quality" prefix="Quality" min={0} value={it.quality} onChange={(v) => setItem(i, { quality: v })} className="w-48 shrink-0" />
                  <Button size="sm" variant="danger-soft" onPress={() => removeItem(i)} aria-label={t('welcome.removeItem')}>
                    <Icon name="x" />
                  </Button>
                </div>
              ))}
      </div>

      {/* Fixed: save button + diff status */}
      <div className="pt-3 shrink-0 flex items-center gap-3">
        <Button size="sm" variant="secondary" onPress={save} isDisabled={saving}>
          {saving
            ? <Spinner size="sm" color="current" />
            : (
                <>
                  <Icon name="save" />
                  {' '}
                  {t('welcome.saveConfig')}
                </>
              )}
        </Button>
        <DiffStatus diff={configDiff} />
      </div>
    </div>
  )
}
```

- [ ] **Step 2: Verify TypeScript compiles cleanly**

```bash
cd /Volumes/Engineering/Icehunter/dune-admin/web && pnpm build 2>&1 | head -40
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add web/src/tabs/WelcomePackageTab/views/PackagesView.tsx
git commit -m "feat(welcome): add unsaved-changes banner and diff status to PackagesView"
```

---

## Task 5: Add saved-pack snapshot, diff, banner, and status to ManagePacksModal

**Files:**

- Modify: `web/src/tabs/PlayersTab/modals/ManagePacksModal.tsx`

- [ ] **Step 1: Update ManagePacksModal**

Replace the full contents of `web/src/tabs/PlayersTab/modals/ManagePacksModal.tsx` with:

```tsx
import type React from 'react'
import { useState, useEffect, useMemo, useCallback, useRef } from 'react'
import { Button, Header, ListBox, Modal, SearchField, Select, Separator, Spinner, toast } from '@heroui/react'
import { useTranslation } from 'react-i18next'
import { Icon, NumberInput } from '../../../dune-ui'
import { api } from '../../../api/client'
import type { GivePack, GivePackItem } from '../../../api/client'

interface ManagePacksModalProps {
  isOpen: boolean
  onClose: () => void
  onSaved: (packs: GivePack[]) => void
  templates: { id: string, name: string }[]
}

type PackDiff = { added: number, updated: number, removed: number, isDirty: boolean }

function DiffStatus({ diff }: { diff: PackDiff }) {
  const parts: { key: string, text: string, cls: string }[] = []
  if (diff.added > 0) parts.push({ key: 'added', text: `${diff.added} added`, cls: 'text-success' })
  if (diff.updated > 0) parts.push({ key: 'updated', text: `${diff.updated} updated`, cls: 'text-warning' })
  if (diff.removed > 0) parts.push({ key: 'removed', text: `${diff.removed} removed`, cls: 'text-danger' })
  if (parts.length === 0) return null
  return (
    <span className="text-xs flex items-center gap-1">
      {parts.map((p, i) => (
        <span key={p.key} className="flex items-center gap-1">
          {i > 0 && <span className="text-muted">·</span>}
          <span className={p.cls}>{p.text}</span>
        </span>
      ))}
    </span>
  )
}

export const ManagePacksModal: React.FC<ManagePacksModalProps> = ({
  isOpen,
  onClose,
  onSaved,
  templates,
}) => {
  const { t } = useTranslation()
  const [packs, setPacks] = useState<GivePack[]>([])
  const [savedPacks, setSavedPacks] = useState<GivePack[]>([])
  const [selectedID, setSelectedID] = useState('')
  const [loading, setLoading] = useState(false)
  const [saving, setSaving] = useState(false)

  // Pack metadata form fields (dual-purpose: create new OR update selected)
  const [formID, setFormID] = useState('')
  const [formName, setFormName] = useState('')
  const [formCategory, setFormCategory] = useState('')
  const [formTier, setFormTier] = useState(1)

  // Add-item row
  const [addQuery, setAddQuery] = useState('')
  const [addSelected, setAddSelected] = useState('')
  const [addQty, setAddQty] = useState(1)
  const [addQuality, setAddQuality] = useState(0)

  const loadPacks = useCallback(() => {
    setLoading(true)
    api.givePacks.config()
      .then((cfg) => {
        const loaded = cfg.packs ?? []
        setPacks(loaded)
        setSavedPacks(loaded)
        setSelectedID(loaded[0]?.id ?? '')
      })
      .catch((e) => toast.danger(e instanceof Error ? e.message : String(e)))
      .finally(() => setLoading(false))
  }, [])

  useEffect(() => {
    if (!isOpen) return
    void Promise.resolve().then(loadPacks)
  }, [isOpen, loadPacks])

  // Pre-populate form fields when selection changes (useRef avoids re-fire on item edits)
  const packsRef = useRef(packs)
  useEffect(() => {
    packsRef.current = packs
  }, [packs])

  useEffect(() => {
    const pack = packsRef.current.find((p) => p.id === selectedID)
    if (pack) {
      setFormID(pack.id)
      setFormName(pack.name)
      setFormCategory(pack.category)
      setFormTier(pack.tier)
    }
    else {
      setFormID('')
      setFormName('')
      setFormCategory('')
      setFormTier(1)
    }
  }, [selectedID])

  const nameMap = useMemo(() => new Map(templates.map((t) => [t.id, t.name])), [templates])

  const sortedPacks = useMemo(
    () => [...packs].sort((a, b) => a.category.localeCompare(b.category) || a.tier - b.tier),
    [packs],
  )

  const groupedPacks = useMemo(() => {
    const groups: Record<string, GivePack[]> = {}
    for (const p of sortedPacks) {
      if (!groups[p.category]) groups[p.category] = []
      groups[p.category].push(p)
    }
    return Object.entries(groups)
  }, [sortedPacks])

  const packDiff = useMemo((): PackDiff => {
    const savedIds = new Set(savedPacks.map((p) => p.id))
    const currentIds = new Set(packs.map((p) => p.id))
    const savedMap = new Map(savedPacks.map((p) => [p.id, p]))
    const added = packs.filter((p) => !savedIds.has(p.id)).length
    const removed = savedPacks.filter((p) => !currentIds.has(p.id)).length
    const updated = packs.filter((p) => {
      if (!savedIds.has(p.id)) return false
      return JSON.stringify(p) !== JSON.stringify(savedMap.get(p.id))
    }).length
    return { added, updated, removed, isDirty: added + updated + removed > 0 }
  }, [packs, savedPacks])

  const selectedPack = packs.find((p) => p.id === selectedID)
  const items: GivePackItem[] = selectedPack?.items ?? []

  const setItems = (next: GivePackItem[]) => {
    setPacks(packs.map((p) => (p.id === selectedID ? { ...p, items: next } : p)))
  }

  const addFiltered = useMemo(() => {
    if (!addQuery) return []
    const q = addQuery.toLowerCase()
    return templates
      .filter((tpl) => tpl.id.toLowerCase().includes(q) || tpl.name.toLowerCase().includes(q))
      .slice(0, 100)
  }, [templates, addQuery])

  const pickTemplate = (tpl: { id: string, name: string }) => {
    setAddSelected(tpl.id)
    setAddQuery(tpl.name ? `${tpl.id}  —  ${tpl.name}` : tpl.id)
  }

  const addItem = () => {
    if (!addSelected) return
    setItems([...items, { template: addSelected, qty: addQty, quality: addQuality }])
    setAddQuery('')
    setAddSelected('')
    setAddQty(1)
    setAddQuality(0)
  }

  const removeItem = (i: number) => setItems(items.filter((_, idx) => idx !== i))
  const setItem = (i: number, patch: Partial<GivePackItem>) =>
    setItems(items.map((it, idx) => (idx === i ? { ...it, ...patch } : it)))

  // True when the form is editing an existing pack's metadata
  const isUpdating = selectedID !== '' && formID.trim() === selectedID

  const applyPack = () => {
    const id = formID.trim()
    const name = formName.trim()
    const category = formCategory.trim()
    if (!id || !name || !category) return
    if (isUpdating) {
      setPacks((prev) => prev.map((p) =>
        p.id === selectedID ? { ...p, id, name, category, tier: formTier } : p,
      ))
      setSelectedID(id)
    }
    else {
      if (packs.some((p) => p.id === id)) {
        toast.warning(t('players.givePacks.duplicateId'))
        return
      }
      setPacks((prev) => [...prev, { id, name, category, tier: formTier, items: [] }])
      setSelectedID(id)
    }
  }

  const clearPackForm = () => {
    setFormID('')
    setFormName('')
    setFormCategory('')
    setFormTier(1)
  }

  const deletePack = (id: string) => {
    const next = packs.filter((p) => p.id !== id)
    setPacks(next)
    if (selectedID === id) setSelectedID(next[0]?.id ?? '')
  }

  const save = async () => {
    setSaving(true)
    try {
      const cfg = await api.givePacks.saveConfig({ packs })
      setSavedPacks(cfg.packs)
      toast.success(t('players.givePacks.saved'))
      onSaved(cfg.packs)
    }
    catch (e) {
      toast.danger(t('players.givePacks.saveFailed', { message: e instanceof Error ? e.message : String(e) }))
    }
    finally {
      setSaving(false)
    }
  }

  if (!isOpen) return null

  return (
    <Modal.Backdrop isOpen onOpenChange={(v) => { if (!v) onClose() }}>
      <Modal.Container size="cover" scroll="outside">
        <Modal.Dialog>
          <Modal.CloseTrigger />
          <Modal.Header>
            <Modal.Heading className="text-accent">{t('players.givePacks.title')}</Modal.Heading>
          </Modal.Header>
          <Modal.Body className="flex flex-col gap-4 h-[80vh] min-h-0">
            {loading
              ? <Spinner size="sm" color="current" />
              : (
                  <div className="flex flex-col h-full min-h-0 gap-3">

                    {/* Unsaved changes banner */}
                    {packDiff.isDirty && (
                      <div className="shrink-0 rounded-[var(--radius)] px-4 py-2 text-xs font-medium bg-warning/10 border border-warning/40 text-warning flex items-center gap-2">
                        <Icon name="triangle-alert" />
                        <span>You have unsaved changes — click Save Config to persist them.</span>
                      </div>
                    )}

                    {/* Pack picker + metadata — single row */}
                    <div className="flex flex-wrap items-center gap-2 shrink-0 pb-1 border-b border-border">
                      <Select
                        aria-label={t('players.givePacks.editingPack')}
                        selectedKey={selectedID || null}
                        onSelectionChange={(k) => setSelectedID(k ? String(k) : '')}
                        className="w-56"
                      >
                        <Select.Trigger>
                          <Select.Value>
                            {!selectedID
                              ? '— select —'
                              : selectedPack
                                ? `${selectedPack.category} — ${selectedPack.name}`
                                : selectedID}
                          </Select.Value>
                          <Select.Indicator />
                        </Select.Trigger>
                        <Select.Popover>
                          <ListBox>
                            <ListBox.Item key="_none" id="" textValue="— select —">
                              — select —
                              <ListBox.ItemIndicator />
                            </ListBox.Item>
                            {groupedPacks.map(([cat, catPacks], i) => (
                              <ListBox.Section key={cat}>
                                <Header>{cat}</Header>
                                {catPacks.map((p) => (
                                  <ListBox.Item key={p.id} id={p.id} textValue={`${cat} — ${p.name}`}>
                                    {p.name}
                                    <ListBox.ItemIndicator />
                                  </ListBox.Item>
                                ))}
                                {i < groupedPacks.length - 1 && <Separator />}
                              </ListBox.Section>
                            ))}
                          </ListBox>
                        </Select.Popover>
                      </Select>
                      {selectedID && (
                        <Button size="sm" variant="ghost" onPress={() => deletePack(selectedID)} aria-label={t('players.givePacks.deletePack')}>
                          <Icon name="trash-2" />
                        </Button>
                      )}
                      <Button size="sm" variant="ghost" onPress={clearPackForm} aria-label={t('players.givePacks.newPack')}>
                        <Icon name="file-plus" />
                        {' '}
                        {t('players.givePacks.newPack')}
                      </Button>
                      <input
                        className="bg-surface border border-border rounded-[var(--radius)] px-3 py-2 text-sm text-foreground placeholder:text-muted w-28"
                        aria-label={t('players.givePacks.packId')}
                        placeholder={t('players.givePacks.packId')}
                        value={formID}
                        onChange={(e) => setFormID(e.target.value)}
                        onKeyDown={(e) => { if (e.key === 'Enter') applyPack() }}
                      />
                      <input
                        className="bg-surface border border-border rounded-[var(--radius)] px-3 py-2 text-sm text-foreground placeholder:text-muted w-24"
                        aria-label={t('players.givePacks.packName')}
                        placeholder={t('players.givePacks.packName')}
                        value={formName}
                        onChange={(e) => setFormName(e.target.value)}
                        onKeyDown={(e) => { if (e.key === 'Enter') applyPack() }}
                      />
                      <input
                        className="bg-surface border border-border rounded-[var(--radius)] px-3 py-2 text-sm text-foreground placeholder:text-muted w-28"
                        aria-label={t('players.givePacks.category')}
                        placeholder={t('players.givePacks.category')}
                        value={formCategory}
                        onChange={(e) => setFormCategory(e.target.value)}
                        onKeyDown={(e) => { if (e.key === 'Enter') applyPack() }}
                      />
                      <NumberInput ariaLabel={t('players.givePacks.tier')} min={1} value={formTier} onChange={setFormTier} className="w-24" />
                      <Button
                        size="sm"
                        onPress={applyPack}
                        isDisabled={!formID.trim() || !formName.trim() || !formCategory.trim()}
                      >
                        <Icon name={isUpdating ? 'check' : 'plus'} />
                        {' '}
                        {isUpdating ? t('players.givePacks.updatePack') : t('players.givePacks.addPack')}
                      </Button>
                    </div>

                    {/* Item add row (only when a pack is selected) */}
                    {selectedID && (
                      <div className="flex items-center gap-2 shrink-0">
                        <div className="relative flex-1">
                          <SearchField
                            value={addQuery}
                            onChange={(v) => {
                              setAddQuery(v)
                              setAddSelected('')
                            }}
                            className="w-full"
                          >
                            <SearchField.Group>
                              <SearchField.SearchIcon />
                              <SearchField.Input placeholder={t('players.givePacks.searchTemplates')} />
                              <SearchField.ClearButton />
                            </SearchField.Group>
                          </SearchField>
                          {addFiltered.length > 0 && (
                            <div className="absolute z-50 w-full mt-1 rounded-[var(--radius)] border border-border bg-surface overflow-y-auto max-h-52">
                              {addFiltered.map((tpl) => (
                                <div
                                  key={tpl.id}
                                  className="px-3 py-1.5 text-xs cursor-pointer hover:bg-surface-hover"
                                  onClick={() => pickTemplate(tpl)}
                                >
                                  <span className="font-mono">{tpl.id}</span>
                                  {tpl.name && (
                                    <span className="text-muted">
                                      {' — '}
                                      {tpl.name}
                                    </span>
                                  )}
                                </div>
                              ))}
                            </div>
                          )}
                        </div>
                        <NumberInput prefix={t('players.give.qty')} ariaLabel={t('players.give.qty')} min={1} value={addQty} onChange={setAddQty} className="w-48 shrink-0" />
                        <NumberInput prefix={t('players.give.quality')} ariaLabel={t('players.give.quality')} min={0} value={addQuality} onChange={setAddQuality} className="w-48 shrink-0" />
                        <Button size="sm" onPress={addItem} isDisabled={!addSelected} className="shrink-0">
                          <Icon name="plus" />
                          {' '}
                          {t('players.givePacks.addItem')}
                        </Button>
                      </div>
                    )}

                    {/* Item list (scrollable) */}
                    <div className="flex-1 min-h-0 overflow-y-auto flex flex-col gap-1.5 pr-1">
                      {packs.length === 0
                        ? <p className="text-xs text-muted">{t('players.givePacks.noPacks')}</p>
                        : !selectedID
                            ? <p className="text-xs text-muted">{t('players.givePacks.noPackSelected')}</p>
                            : items.length === 0
                              ? <p className="text-xs text-muted">{t('players.givePacks.noItemsYet')}</p>
                              : items.map((it, i) => (
                                  <div
                                    key={i}
                                    className="flex items-center gap-2 px-3 py-1.5 rounded-[var(--radius)] text-xs bg-surface border border-border"
                                  >
                                    <div className="flex-1 min-w-0 leading-tight">
                                      <div className="truncate text-foreground">{nameMap.get(it.template) || it.template}</div>
                                      {nameMap.get(it.template) && (
                                        <div className="font-mono text-[10px] text-muted truncate">{it.template}</div>
                                      )}
                                    </div>
                                    <NumberInput ariaLabel={t('players.give.qty')} prefix={t('players.give.qty')} min={1} value={it.qty} onChange={(v) => setItem(i, { qty: v })} className="w-48 shrink-0" />
                                    <NumberInput ariaLabel={t('players.give.quality')} prefix={t('players.give.quality')} min={0} value={it.quality} onChange={(v) => setItem(i, { quality: v })} className="w-48 shrink-0" />
                                    <Button size="sm" variant="danger-soft" onPress={() => removeItem(i)} aria-label={t('players.givePacks.removeItem')}>
                                      <Icon name="x" />
                                    </Button>
                                  </div>
                                ))}
                    </div>

                    {/* Save button + diff status */}
                    <div className="pt-3 shrink-0 border-t border-border flex items-center gap-3">
                      <Button size="sm" onPress={save} isDisabled={saving}>
                        {saving
                          ? <Spinner size="sm" color="current" />
                          : <Icon name="save" />}
                        {' '}
                        {t('players.givePacks.save')}
                      </Button>
                      <DiffStatus diff={packDiff} />
                    </div>

                  </div>
                )}
          </Modal.Body>
        </Modal.Dialog>
      </Modal.Container>
    </Modal.Backdrop>
  )
}
```

- [ ] **Step 2: Verify TypeScript compiles cleanly**

```bash
cd /Volumes/Engineering/Icehunter/dune-admin/web && pnpm build 2>&1 | head -40
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add web/src/tabs/PlayersTab/modals/ManagePacksModal.tsx
git commit -m "feat(give-items): add unsaved-changes banner and diff status to ManagePacksModal"
```

---

## Task 6: Final verification

- [ ] **Step 1: Run Go checks**

```bash
cd /Volumes/Engineering/Icehunter/dune-admin && make verify
```

Expected: all Go checks pass (no Go files were modified; this confirms nothing was broken).

- [ ] **Step 2: Run frontend lint**

```bash
cd /Volumes/Engineering/Icehunter/dune-admin/web && pnpm lint
```

Expected: no lint errors.

- [ ] **Step 3: Manual smoke test**

Start the dev server:

```bash
cd /Volumes/Engineering/Icehunter/dune-admin && make dev
```

Then verify in browser:

1. Open **Welcome Packages → Config**: make a change (e.g. toggle enabled). Banner appears. Status shows "settings changed". Save → banner disappears.
2. Open **Welcome Packages → Packages**: add a version. Banner appears. Status shows "1 added". Save → banner disappears.
3. Open **Give Items → Manage Packs**: add a pack. Banner appears. Status shows "1 added". Delete it without saving → status shows "0 added · 0 updated · 0 removed" (no banner). Add it back, plus delete a different existing pack → status shows "1 added · 1 removed". Save → banner and status clear.
