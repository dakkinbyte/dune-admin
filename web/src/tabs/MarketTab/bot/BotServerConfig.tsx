import { useState, useEffect } from 'react'
import { Button, Spinner, toast } from '@heroui/react'
import { api, MASKED } from '../../../api/client'
import type { AppConfig } from '../../../api/client'
import { Panel, SectionLabel } from '../../../dune-ui'

const inputCls = 'bg-surface border border-border rounded px-2 py-1.5 text-sm text-foreground w-full font-mono placeholder:text-muted/50 focus:outline-none focus:border-accent/60'

// Restrict the set() helper to string-typed fields so it can't accidentally coerce
// numeric/boolean AppConfig keys to strings (which the backend would reject or misparse).
type StringAppConfigKey = { [K in keyof AppConfig]: AppConfig[K] extends string ? K : never }[keyof AppConfig]

export default function BotServerConfig() {
  const [cfg, setCfg] = useState<AppConfig | null>(null)
  const [loading, setLoading] = useState(false)
  const [saving, setSaving] = useState(false)

  useEffect(() => {
    Promise.resolve()
      .then(() => setLoading(true))
      .then(() => api.config.get())
      .then(setCfg)
      .catch(() => toast.danger('Failed to load server config'))
      .finally(() => setLoading(false))
  }, [])

  const set = (key: StringAppConfigKey) => (e: React.ChangeEvent<HTMLInputElement>) =>
    setCfg((prev) => prev ? { ...prev, [key]: e.target.value } : prev)

  const setBool = (key: keyof AppConfig) => (e: React.ChangeEvent<HTMLInputElement>) =>
    setCfg((prev) => prev ? { ...prev, [key]: e.target.checked } : prev)

  const save = async () => {
    if (!cfg) return
    setSaving(true)
    try {
      // Sends the full AppConfig. The backend treats MASKED sentinel values as
      // "unchanged" for credential fields so they are never overwritten on save.
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
        <label className="mt-2 flex items-center gap-2 cursor-pointer">
          <input
            type="checkbox"
            checked={cfg.market_bot_enabled}
            onChange={setBool('market_bot_enabled')}
            className="accent-accent w-4 h-4"
          />
          <span className="text-sm text-foreground">Enable embedded bot</span>
          <span className="text-xs text-muted">(restart required)</span>
        </label>
        <div className="mt-3 grid grid-cols-1 gap-3 sm:grid-cols-2">
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
