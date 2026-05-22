import { useState, useEffect, useRef } from 'react'
import { Button, Modal, Spinner, toast, Label } from '@heroui/react'
import { api } from '../api/client'
import type { BlueprintRow, Player } from '../api/client'

export default function BlueprintsTab() {
  const [blueprints, setBlueprints] = useState<BlueprintRow[]>([])
  const [loading, setLoading] = useState(false)
  const [showImport, setShowImport] = useState(false)

  const load = async () => {
    setLoading(true)
    try {
      const data = await api.blueprints.list()
      setBlueprints(data)
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : String(e)
      toast.danger(`Failed to load blueprints: ${msg}`)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    load()
  }, [])

  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: '100%', gap: '16px' }}>
      <div className="flex items-center justify-between shrink-0">
        <div>
          <h2 className="text-lg font-semibold" style={{ color: 'var(--color-primary)' }}>
            Blueprints
          </h2>
          <p className="text-sm" style={{ color: 'var(--color-text-dim)' }}>
            Manage saved base blueprints. Export or import player constructions.
          </p>
        </div>
        <div className="flex gap-2">
          <Button variant="outline" size="sm" onPress={load} isDisabled={loading}>
            {loading ? <Spinner size="sm" color="current" /> : null}
            Refresh
          </Button>
          <Button size="sm" onPress={() => setShowImport(true)}>
            Import Blueprint
          </Button>
        </div>
      </div>

      {loading ? (
        <div className="flex justify-center py-12">
          <Spinner size="lg" />
        </div>
      ) : (
        <div className="rounded-lg" style={{ flex: 1, minHeight: 0, overflowY: 'auto', border: '1px solid #2a2418' }}>
          <table className="w-full text-sm">
              <thead style={{ position: 'sticky', top: 0, zIndex: 1, background: '#1a1610' }}>
                <tr style={{ borderBottom: '1px solid #2a2418' }}>
                  {['ID', 'Owner', 'Name', 'Item ID', 'Pieces', 'Placeables', 'Actions'].map(h => (
                    <th key={h} className="text-left px-4 py-2 font-semibold text-xs uppercase tracking-wide" style={{ color: 'var(--color-primary)' }}>
                      {h}
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {blueprints.map((bp, i) => (
                  <tr key={bp.id} style={{ borderBottom: '1px solid #1a1610', background: i % 2 === 0 ? '#0d0b07' : '#111009' }}>
                    <td className="px-4 py-2 font-mono text-xs" style={{ color: 'var(--color-text)' }}>{bp.id}</td>
                    <td className="px-4 py-2 text-xs" style={{ color: 'var(--color-text)' }}>{bp.owner_name}</td>
                    <td className="px-4 py-2 text-xs" style={{ color: 'var(--color-text)' }}>{bp.name || '—'}</td>
                    <td className="px-4 py-2 font-mono text-xs" style={{ color: 'var(--color-text-dim)' }}>{bp.item_id}</td>
                    <td className="px-4 py-2 text-xs" style={{ color: 'var(--color-text-dim)' }}>{bp.pieces}</td>
                    <td className="px-4 py-2 text-xs" style={{ color: 'var(--color-text-dim)' }}>{bp.placeables}</td>
                    <td className="px-4 py-2">
                      <a
                        href={api.blueprints.exportUrl(bp.id)}
                        download={bp.name ? `${bp.name}.json` : `blueprint-${bp.id}-${bp.owner_name}.json`}
                      >
                        <Button size="sm" variant="outline">
                          Export
                        </Button>
                      </a>
                    </td>
                  </tr>
                ))}
                {blueprints.length === 0 && (
                  <tr>
                    <td colSpan={7} className="px-4 py-8 text-center text-sm" style={{ color: 'var(--color-text-dim)' }}>
                      No blueprints found.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
        </div>
      )}

      {/* Import Modal */}
      <ImportModal
        open={showImport}
        onClose={() => setShowImport(false)}
        onSuccess={() => { setShowImport(false); load() }}
        players={[]}
      />
    </div>
  )
}

function ImportModal({
  open,
  onClose,
  onSuccess,
}: {
  open: boolean
  onClose: () => void
  onSuccess: () => void
  players: { id: number; name: string }[]
}) {
  const [file, setFile] = useState<File | null>(null)
  const [search, setSearch] = useState('')
  const [players, setPlayers] = useState<Player[]>([])
  const [selectedPlayer, setSelectedPlayer] = useState<Player | null>(null)
  const [showDropdown, setShowDropdown] = useState(false)
  const [submitting, setSubmitting] = useState(false)
  const searchRef = useRef<HTMLInputElement>(null)

  useEffect(() => {
    if (!open) return
    setFile(null)
    setSearch('')
    setSelectedPlayer(null)
    api.players.list().then(setPlayers).catch(() => {})
  }, [open])

  const filtered = search.trim()
    ? players.filter(p => p.name.toLowerCase().includes(search.toLowerCase()))
    : players

  const handleSubmit = async () => {
    if (!file) { toast.warning('Select a blueprint file'); return }
    if (!selectedPlayer) { toast.warning('Select a player'); return }
    setSubmitting(true)
    try {
      const res = await api.blueprints.import(file, selectedPlayer.id)
      if (res.ok) {
        toast.success('Blueprint imported successfully')
        onSuccess()
      } else {
        toast.danger(`Import failed: ${res.error ?? 'unknown error'}`)
      }
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : String(e)
      toast.danger(`Import failed: ${msg}`)
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <Modal>
      <Modal.Backdrop isOpen={open} onOpenChange={v => !v && onClose()}>
        <Modal.Container>
          <Modal.Dialog>
            <Modal.CloseTrigger />
            <Modal.Header>
              <Modal.Heading>Import Blueprint</Modal.Heading>
            </Modal.Header>
            <Modal.Body>
              <div className="flex flex-col gap-4">
                <div className="flex flex-col gap-1">
                  <Label className="text-sm" style={{ color: 'var(--color-text-dim)' }}>
                    Blueprint File (.json)
                  </Label>
                  <input
                    type="file"
                    accept=".json"
                    className="text-sm"
                    style={{ color: 'var(--color-text)' }}
                    onChange={e => setFile(e.target.files?.[0] ?? null)}
                  />
                </div>
                <div className="flex flex-col gap-1" style={{ position: 'relative' }}>
                  <Label className="text-sm" style={{ color: 'var(--color-text-dim)' }}>
                    Player
                  </Label>
                  <input
                    ref={searchRef}
                    className="rounded px-3 py-1.5 text-sm border"
                    style={{ background: 'var(--color-surface)', color: 'var(--color-text)', borderColor: '#2a2418', outline: 'none' }}
                    placeholder="Search by name…"
                    value={selectedPlayer ? selectedPlayer.name : search}
                    onChange={e => { setSearch(e.target.value); setSelectedPlayer(null); setShowDropdown(true) }}
                    onFocus={() => setShowDropdown(true)}
                    onBlur={() => setTimeout(() => setShowDropdown(false), 150)}
                  />
                  {showDropdown && filtered.length > 0 && (
                    <div style={{
                      position: 'absolute', top: '100%', left: 0, right: 0, zIndex: 50,
                      background: '#0d0b07', border: '1px solid #2a2418', borderRadius: 6,
                      maxHeight: 200, overflowY: 'auto', marginTop: 2,
                    }}>
                      {filtered.slice(0, 20).map(p => (
                        <div
                          key={p.id}
                          onMouseDown={() => { setSelectedPlayer(p); setSearch(''); setShowDropdown(false) }}
                          style={{ padding: '6px 12px', cursor: 'pointer', borderBottom: '1px solid #1a1610' }}
                          onMouseEnter={e => (e.currentTarget.style.background = '#1a1610')}
                          onMouseLeave={e => (e.currentTarget.style.background = 'transparent')}
                        >
                          <span className="text-sm" style={{ color: 'var(--color-text)' }}>{p.name}</span>
                          <span className="text-xs ml-2" style={{ color: 'var(--color-text-dim)' }}>#{p.id}</span>
                        </div>
                      ))}
                    </div>
                  )}
                  {selectedPlayer && (
                    <p className="text-xs mt-0.5" style={{ color: 'var(--color-text-dim)' }}>
                      Actor ID: {selectedPlayer.id}
                    </p>
                  )}
                </div>
              </div>
            </Modal.Body>
            <Modal.Footer>
              <Button variant="tertiary" onPress={onClose}>Cancel</Button>
              <Button onPress={handleSubmit} isDisabled={submitting || !file || !selectedPlayer}>
                {submitting ? <Spinner size="sm" color="current" /> : null}
                Import
              </Button>
            </Modal.Footer>
          </Modal.Dialog>
        </Modal.Container>
      </Modal.Backdrop>
    </Modal>
  )
}
