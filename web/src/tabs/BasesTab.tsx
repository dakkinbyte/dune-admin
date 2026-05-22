import { useState, useEffect } from 'react'
import { Button, Spinner, toast } from '@heroui/react'
import { api, ApiError } from '../api/client'
import type { BaseRow } from '../api/client'

export default function BasesTab() {
  const [bases, setBases] = useState<BaseRow[]>([])
  const [loading, setLoading] = useState(false)
  const [unsupported, setUnsupported] = useState(false)

  const load = async () => {
    setLoading(true)
    setUnsupported(false)
    try {
      const data = await api.bases.list()
      setBases(data)
    } catch (e: unknown) {
      if (e instanceof ApiError && e.status === 404) {
        setUnsupported(true)
      } else {
        const msg = e instanceof Error ? e.message : String(e)
        toast.danger(`Failed to load bases: ${msg}`)
      }
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => { load() }, [])

  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: '100%', gap: '16px' }}>
      <div className="flex items-center justify-between shrink-0">
        <div>
          <h2 className="text-lg font-semibold" style={{ color: 'var(--color-primary)' }}>
            Bases
          </h2>
          <p className="text-sm" style={{ color: 'var(--color-text-dim)' }}>
            Live in-world player bases. Export any base as a solido-compatible blueprint.
          </p>
        </div>
        <Button variant="outline" size="sm" onPress={load} isDisabled={loading}>
          {loading ? <Spinner size="sm" color="current" /> : null}
          Refresh
        </Button>
      </div>

      {loading ? (
        <div className="flex justify-center py-12">
          <Spinner size="lg" />
        </div>
      ) : unsupported ? (
        <div className="flex flex-col items-center justify-center py-16 gap-3">
          <p className="text-sm font-medium" style={{ color: 'var(--color-primary)' }}>
            Feature not available
          </p>
          <p className="text-xs text-center" style={{ color: 'var(--color-text-dim)', maxWidth: 320 }}>
            This version of the dune-admin binary does not support base listing.
            Upgrade to the latest release to use this feature.
          </p>
        </div>
      ) : (
        <div className="rounded-lg" style={{ flex: 1, minHeight: 0, overflowY: 'auto', border: '1px solid #2a2418' }}>
          <table className="w-full text-sm">
            <thead style={{ position: 'sticky', top: 0, zIndex: 1, background: '#1a1610' }}>
              <tr style={{ borderBottom: '1px solid #2a2418' }}>
                {['ID', 'Name', 'Pieces', 'Placeables', 'Actions'].map(h => (
                  <th key={h} className="text-left px-4 py-2 font-semibold text-xs uppercase tracking-wide" style={{ color: 'var(--color-primary)' }}>
                    {h}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {bases.map((base, i) => (
                <tr key={base.id} style={{ borderBottom: '1px solid #1a1610', background: i % 2 === 0 ? '#0d0b07' : '#111009' }}>
                  <td className="px-4 py-2 font-mono text-xs" style={{ color: 'var(--color-text)' }}>{base.id}</td>
                  <td className="px-4 py-2 text-xs" style={{ color: 'var(--color-text)' }}>{base.name || '—'}</td>
                  <td className="px-4 py-2 text-xs" style={{ color: 'var(--color-text-dim)' }}>{base.pieces}</td>
                  <td className="px-4 py-2 text-xs" style={{ color: 'var(--color-text-dim)' }}>{base.placeables}</td>
                  <td className="px-4 py-2">
                    <a
                      href={api.bases.exportUrl(base.id)}
                      download={base.name ? `${base.name}.json` : `base-${base.id}.json`}
                    >
                      <Button size="sm" variant="outline">Export</Button>
                    </a>
                  </td>
                </tr>
              ))}
              {bases.length === 0 && (
                <tr>
                  <td colSpan={5} className="px-4 py-8 text-center text-sm" style={{ color: 'var(--color-text-dim)' }}>
                    No bases found.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}
