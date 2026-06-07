import type React from 'react'
import { useMemo, useState } from 'react'
import { Button, ListBox, SearchField, Select, Spinner } from '@heroui/react'
import { useTranslation } from 'react-i18next'
import { Icon, NumberInput, PageHeader } from '../../../dune-ui'
import type { WelcomeSharedProps, WelcomePackageItem } from '../types'
import type { WelcomePackage } from '../../../api/client'
import { DiffStatus } from '../components/DiffStatus'

type PackagesViewProps = Pick<
  WelcomeSharedProps,
  'packages' | 'setPackages' | 'activeVersions' | 'templates' | 'save' | 'saving' | 'load' | 'loading' | 'configDiff'
>

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
