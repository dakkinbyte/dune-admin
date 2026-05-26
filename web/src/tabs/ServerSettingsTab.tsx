import { useState, useEffect, useCallback, useRef } from 'react'
import { Button, ListBox, Select, Spinner, toast } from '@heroui/react'
import { api } from '../api/client'
import type { ServerSetting, ServerSettingUpdate, RawSection } from '../api/client'
import { PageHeader, Panel, SectionLabel, Icon } from '../dune-ui'

const CATEGORY_ORDER = [
  'Survival', 'Progression', 'Harvesting', 'Building', 'Inventory',
  'Guilds & Economy', 'Storm Cycle', 'PvP & Security', 'Spice', 'Taxation', 'Sandworm',
]

const SOURCE_FILE: Record<string, string> = {
  userGame:      'UserGame.ini',
  userOverrides: 'UserOverrides.ini',
  userEngine:    'UserEngine.ini',
}

function groupByCategory(items: ServerSetting[]) {
  const map = new Map<string, ServerSetting[]>()
  for (const item of items) {
    const arr = map.get(item.category) ?? []
    arr.push(item)
    map.set(item.category, arr)
  }
  const ordered: [string, ServerSetting[]][] = []
  for (const cat of CATEGORY_ORDER) {
    if (map.has(cat)) ordered.push([cat, map.get(cat)!])
  }
  for (const [cat, items] of map) {
    if (!CATEGORY_ORDER.includes(cat)) ordered.push([cat, items])
  }
  return ordered
}

function sourceLabel(s: string) {
  if (s === 'userOverrides') return { text: 'UserOverrides.ini', cls: 'text-accent' }
  if (s === 'userGame')      return { text: 'UserGame.ini',      cls: 'text-warning' }
  return null
}

function shortSection(section: string) {
  // "/Script/DuneSandbox.BuildingSettings" → "BuildingSettings"
  const dot = section.lastIndexOf('.')
  return dot >= 0 ? section.slice(dot + 1) : section
}

function SettingRow({
  item, pending, onChange, onReset,
}: {
  item: ServerSetting
  pending: string | undefined
  onChange: (value: string) => void
  onReset: () => void
}) {
  const display  = pending !== undefined ? pending : item.current
  const dirty    = pending !== undefined && pending !== item.current
  const src      = sourceLabel(item.source)
  const isDefault = item.current === item.default && !pending

  return (
    <div className="flex items-start gap-3 py-2.5 border-b border-border/40 last:border-0">
      <div className="flex-1 min-w-0">
        <div className="flex items-center gap-2 flex-wrap">
          <span className="text-sm font-medium text-foreground">{item.label}</span>
          {src && <span className={`text-xs ${src.cls}`}>{src.text}</span>}
          {dirty && <span className="text-xs text-warning">unsaved</span>}
        </div>
        <p className="text-xs text-muted mt-0.5 leading-relaxed">{item.description}</p>
        {!isDefault && !dirty && (
          <p className="text-xs text-muted/60 mt-0.5">default: {item.default}</p>
        )}
      </div>

      <div className="flex items-center gap-1.5 shrink-0">
        {item.type === 'bool' ? (
          <Select selectedKey={display} onSelectionChange={k => onChange(String(k))} className="w-32">
            <Select.Trigger className="h-7 text-xs">
              <Select.Value /><Select.Indicator />
            </Select.Trigger>
            <Select.Popover>
              <ListBox>
                <ListBox.Item id="True"  textValue="True">True<ListBox.ItemIndicator /></ListBox.Item>
                <ListBox.Item id="False" textValue="False">False<ListBox.ItemIndicator /></ListBox.Item>
              </ListBox>
            </Select.Popover>
          </Select>
        ) : (
          <input
            type="number"
            step={item.type === 'float' ? '0.01' : '1'}
            value={display}
            onChange={e => onChange(e.target.value)}
            className="w-28 bg-surface border border-border rounded px-2 py-1 text-xs font-mono text-foreground focus:outline-none focus:border-accent/60 text-right"
          />
        )}
        <button onClick={onReset} title="Reset to default" className="text-muted/50 hover:text-muted transition-colors">
          <Icon name="x" className="w-3.5 h-3.5" />
        </button>
      </div>
    </div>
  )
}

function linesToText(lines: RawSection['lines']) {
  return lines.map(l => `${l.prefix}${l.key}=${l.value}`).join('\n')
}

function RawSectionPanel({ section, onSaved }: { section: RawSection; onSaved: () => void }) {
  const fileLabel = SOURCE_FILE[section.source] ?? section.source
  const srcCls = section.source === 'userOverrides' ? 'text-accent'
               : section.source === 'userEngine'    ? 'text-info'
               : 'text-warning'

  const [editing, setEditing] = useState(false)
  const [draft, setDraft]     = useState('')
  const [saving, setSaving]   = useState(false)
  const textareaRef           = useRef<HTMLTextAreaElement>(null)

  const target = 'userOverrides' as const
  const targetLabel = 'UserOverrides.ini'

  const startEdit = () => {
    setDraft(linesToText(section.lines))
    setEditing(true)
    setTimeout(() => textareaRef.current?.focus(), 0)
  }

  const cancel = () => setEditing(false)

  const save = async () => {
    setSaving(true)
    try {
      await api.serverSettings.updateRaw(section.section, target, draft)
      toast.success(`Saved to ${targetLabel}`)
      setEditing(false)
      onSaved()
    } catch (e: unknown) {
      toast.danger(`Save failed: ${e instanceof Error ? e.message : String(e)}`)
    } finally {
      setSaving(false)
    }
  }

  // Group lines by bare key so array entries cluster together
  const grouped: { key: string; lines: typeof section.lines }[] = []
  const seen = new Map<string, number>()
  for (const line of section.lines) {
    const idx = seen.get(line.key)
    if (idx !== undefined) {
      grouped[idx].lines.push(line)
    } else {
      seen.set(line.key, grouped.length)
      grouped.push({ key: line.key, lines: [line] })
    }
  }

  return (
    <Panel>
      <div className="flex items-center gap-2 mb-1">
        <SectionLabel>{shortSection(section.section)}</SectionLabel>
        <span className={`text-xs ${srcCls} ml-1`}>{fileLabel}</span>
        <div className="ml-auto flex items-center gap-1">
          {editing ? (
            <>
              <Button size="sm" variant="ghost" onPress={cancel} isDisabled={saving}>
                Cancel
              </Button>
              <Button size="sm" onPress={save} isDisabled={saving}>
                {saving ? <Spinner size="sm" color="current" /> : 'Save'}
              </Button>
            </>
          ) : (
            <Button size="sm" variant="ghost" onPress={startEdit}>
              <Icon name="pencil" className="w-3.5 h-3.5" />
            </Button>
          )}
        </div>
      </div>

      {editing ? (
        <textarea
          ref={textareaRef}
          value={draft}
          onChange={e => setDraft(e.target.value)}
          rows={Math.max(4, draft.split('\n').length + 1)}
          className="w-full bg-surface border border-border rounded px-3 py-2 text-xs font-mono text-foreground focus:outline-none focus:border-accent/60 resize-y"
          spellCheck={false}
        />
      ) : (
        <div className="flex flex-col gap-0.5">
          {grouped.map(({ key, lines }) => (
            <div key={key} className="py-1 border-b border-border/30 last:border-0">
              <span className="text-xs font-mono text-muted">{key}</span>
              {lines.map((l, i) => (
                <div key={i} className="flex items-baseline gap-1.5 mt-0.5 ml-3">
                  {l.prefix && (
                    <span className={`text-xs font-mono w-3 shrink-0 ${l.prefix === '+' ? 'text-success' : 'text-danger'}`}>
                      {l.prefix}
                    </span>
                  )}
                  <span className="text-xs font-mono text-foreground/80 break-all">{l.value}</span>
                </div>
              ))}
            </div>
          ))}
        </div>
      )}
    </Panel>
  )
}

export default function ServerSettingsTab() {
  const [items, setItems]     = useState<ServerSetting[]>([])
  const [raw, setRaw]         = useState<RawSection[]>([])
  const [pending, setPending] = useState<Map<string, string>>(new Map())
  const [loading, setLoading] = useState(true)
  const [saving, setSaving]   = useState(false)
  const [error, setError]     = useState<string | null>(null)

  const load = useCallback(async () => {
    setLoading(true)
    setError(null)
    try {
      const data = await api.serverSettings.get()
      setItems(data.settings ?? [])
      setRaw(data.raw ?? [])
      setPending(new Map())
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : String(e)
      setError(msg)
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => { load() }, [load])

  const pendingKey = (item: ServerSetting) => `${item.section}|${item.key}`

  const handleChange = (item: ServerSetting, value: string) => {
    setPending(prev => { const n = new Map(prev); n.set(pendingKey(item), value); return n })
  }

  const handleReset = (item: ServerSetting) => {
    setPending(prev => { const n = new Map(prev); n.set(pendingKey(item), ''); return n })
  }

  const save = async () => {
    const updates: ServerSettingUpdate[] = []
    for (const [k, v] of pending) {
      const [section, key] = k.split('|')
      updates.push({ section, key, value: v })
    }
    if (updates.length === 0) return
    setSaving(true)
    try {
      const res = await api.serverSettings.update(updates)
      toast.success(res.ok)
      load()
    } catch (e: unknown) {
      toast.danger(`Save failed: ${e instanceof Error ? e.message : String(e)}`)
    } finally {
      setSaving(false)
    }
  }

  const dirtyCount = pending.size

  if (loading) {
    return (
      <div className="flex items-center justify-center h-full gap-2 text-muted">
        <Spinner size="sm" color="current" />
        <span className="text-sm">Loading settings…</span>
      </div>
    )
  }

  if (error) {
    return (
      <div className="flex flex-col h-full gap-3">
        <PageHeader title="Server Settings" />
        <div className="rounded px-4 py-3 text-sm bg-danger/10 border border-danger/40 text-danger">
          {error.includes('server_ini_dir') || error.includes('ini dir')
            ? `Could not locate server INI files: ${error}. For kubectl, ensure the game server PVC is mounted. For docker/local, add server_ini_dir to ~/.dune-admin/config.yaml.`
            : error}
        </div>
      </div>
    )
  }

  const categories = groupByCategory(items)

  // Raw sections grouped by source file for the reference panels
  const rawBySource = new Map<string, RawSection[]>()
  for (const sec of raw) {
    const arr = rawBySource.get(sec.source) ?? []
    arr.push(sec)
    rawBySource.set(sec.source, arr)
  }

  return (
    <div className="flex flex-col h-full gap-3 min-h-0">
      <PageHeader title="Server Settings">
        <div className="flex items-center gap-2">
          <Button size="sm" variant="ghost" onPress={load} isDisabled={loading || saving}>
            <Icon name="refresh-cw" />
          </Button>
          <Button size="sm" onPress={save} isDisabled={dirtyCount === 0 || saving}>
            {saving
              ? <Spinner size="sm" color="current" />
              : `Save${dirtyCount > 0 ? ` (${dirtyCount})` : ''}`}
          </Button>
        </div>
      </PageHeader>

      <p className="text-xs text-muted shrink-0">
        Changes are written to <span className="font-mono">UserOverrides.ini</span>.
        A server restart is required for them to take effect.
      </p>

      <div className="flex-1 min-h-0 overflow-y-auto flex flex-col gap-4 pb-6">

        {/* Typed / schema settings — only configured ones */}
        {categories.map(([cat, catItems]) => (
          <Panel key={cat}>
            <SectionLabel>{cat}</SectionLabel>
            <div>
              {catItems.map(item => (
                <SettingRow
                  key={`${item.section}|${item.key}`}
                  item={item}
                  pending={pending.get(pendingKey(item))}
                  onChange={v => handleChange(item, v)}
                  onReset={() => handleReset(item)}
                />
              ))}
            </div>
          </Panel>
        ))}

        {/* Raw sections — non-schema keys and array entries, grouped by file */}
        {(['userGame', 'userEngine', 'userOverrides'] as const).map(src => {
          const sections = rawBySource.get(src)
          if (!sections?.length) return null
          return (
            <div key={src} className="flex flex-col gap-3">
              <p className="text-xs text-muted shrink-0 px-0.5">
                <span className="font-mono">{SOURCE_FILE[src]}</span>
              </p>
              {sections.map((sec, i) => (
                <RawSectionPanel key={`${src}-${i}`} section={sec} onSaved={load} />
              ))}
            </div>
          )
        })}

      </div>
    </div>
  )
}
