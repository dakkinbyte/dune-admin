import { useState, useEffect } from 'react'
import { Button, Chip, Modal, Spinner, toast } from '@heroui/react'
import { api } from '../../../api/client'
import type { Player, InventoryItem, VehicleRow } from '../../../api/client'
import { DataTable, type Column } from '../../../dune-ui'

type ItemKey = 'template' | 'stack' | 'quality' | 'durability' | 'actions'
type VehicleKey = 'class' | 'location' | 'chassis' | 'name' | 'type'

const ITEM_COLUMNS: Column<ItemKey>[] = [
  { key: 'template',   label: 'Template', isRowHeader: true },
  { key: 'stack',      label: 'Stack' },
  { key: 'quality',    label: 'Quality' },
  { key: 'durability', label: 'Durability' },
  { key: 'actions',    label: '', sortable: false },
]

const VEHICLE_COLUMNS: Column<VehicleKey>[] = [
  { key: 'class',    label: 'Class', isRowHeader: true },
  { key: 'location', label: 'Location' },
  { key: 'chassis',  label: 'Chassis' },
  { key: 'name',     label: 'Name' },
  { key: 'type',     label: 'Type', sortable: false },
]

interface Props {
  player: Player
  open: boolean
  onClose: () => void
}

export function InventoryModal({ player, open, onClose }: Props) {
  const [items, setItems] = useState<InventoryItem[]>([])
  const [loading, setLoading] = useState(false)
  const [vehicles, setVehicles] = useState<VehicleRow[]>([])
  const [vehiclesLoading, setVehiclesLoading] = useState(false)

  useEffect(() => {
    if (!open) {
      setVehicles([])
      return
    }
    setLoading(true)
    setVehiclesLoading(true)
    api.players.inventory(player.id)
      .then(setItems)
      .catch((e: unknown) => toast.danger(e instanceof Error ? e.message : String(e)))
      .finally(() => setLoading(false))
    api.players.vehicles(player.controller_id)
      .then(setVehicles)
      .catch(() => {})
      .finally(() => setVehiclesLoading(false))
  }, [open, player.id, player.controller_id])

  const handleDelete = async (itemId: number) => {
    if (player.online_status === 'Online') {
      const ok = window.confirm('Player is online — deleting items may cause inventory desyncs. Continue?')
      if (!ok) return
    }
    try {
      await api.players.deleteItem(itemId)
      setItems(prev => prev.filter(i => i.id !== itemId))
      toast.success('Item deleted')
    } catch (e: unknown) {
      toast.danger(e instanceof Error ? e.message : String(e))
    }
  }

  const handleRepair = async (item: InventoryItem) => {
    try {
      await api.players.repairItem(item.id)
      setItems(prev => prev.map(i => i.id === item.id ? { ...i, durability: i.max_durability } : i))
      toast.success(`Repaired ${item.name || item.template_id}`)
    } catch (e: unknown) {
      toast.danger(e instanceof Error ? e.message : String(e))
    }
  }

  return (
    <Modal>
      <Modal.Backdrop isOpen={open} onOpenChange={v => !v && onClose()}>
        <Modal.Container size="cover">
          <Modal.Dialog>
            <Modal.CloseTrigger />
            <Modal.Header><Modal.Heading className="text-accent">{player.name} — Inventory</Modal.Heading></Modal.Header>
            <Modal.Body className="flex flex-col gap-4 overflow-hidden">
              {loading ? (
                <div className="flex justify-center py-8"><Spinner size="lg" /></div>
              ) : (
                <div className="flex flex-col gap-4 flex-1 min-h-0 overflow-hidden">
                  {/* Items — fills remaining space and owns its own scroll */}
                  <DataTable<InventoryItem, ItemKey>
                    aria-label="Inventory items"
                    className="flex-1 min-h-0"
                    columns={ITEM_COLUMNS}
                    rows={items}
                    rowId={i => String(i.id)}
                    initialSort={{ column: 'template', direction: 'ascending' }}
                    sortValue={(i, k) => {
                      if (k === 'template')   return i.name || i.template_id
                      if (k === 'stack')      return i.stack_size
                      if (k === 'quality')    return i.quality
                      if (k === 'durability') return typeof i.durability === 'number' ? i.durability : 0
                      return ''
                    }}
                    emptyState={<div className="py-6 text-center text-muted">No items found</div>}
                    renderCell={(i, key) => {
                      switch (key) {
                        case 'template':
                          return (
                            <span className="inline-flex flex-col">
                              <span className="font-semibold">{i.name || i.template_id}</span>
                              {i.name && <span className="font-mono text-muted text-[10px]">{i.template_id}</span>}
                            </span>
                          )
                        case 'stack':      return <span className="text-muted">{i.stack_size}</span>
                        case 'quality':    return <span className="text-muted">{i.quality}</span>
                        case 'durability': return <span className="text-muted">{i.durability} / {i.max_durability}</span>
                        case 'actions':
                          return (
                            <div className="flex gap-1">
                              {i.max_durability !== 'N/A' && (
                                <Button size="sm" variant="ghost" onPress={() => handleRepair(i)}>Repair</Button>
                              )}
                              <Button size="sm" variant="danger-soft" onPress={() => handleDelete(i.id)}>X</Button>
                            </div>
                          )
                      }
                    }}
                  />

                  {/* Vehicles — fixed ~4-row window, scrolls independently */}
                  <div className="shrink-0 flex flex-col gap-2">
                    <div className="flex items-center gap-2">
                      <h3 className="text-sm font-semibold text-accent">Vehicles</h3>
                      {vehiclesLoading && <Spinner size="sm" color="current" />}
                    </div>
                    <DataTable<VehicleRow, VehicleKey>
                      aria-label="Vehicles"
                      className="max-h-[180px]"
                      columns={VEHICLE_COLUMNS}
                      rows={vehicles}
                      rowId={v => String(v.id)}
                      initialSort={{ column: 'class', direction: 'ascending' }}
                      sortValue={(v, k) => {
                        if (k === 'class')    return v.class
                        if (k === 'location') return v.map ?? ''
                        if (k === 'chassis')  return v.chassis_durability
                        if (k === 'name')     return v.vehicle_name ?? ''
                        return ''
                      }}
                      emptyState={<div className="py-6 text-center text-muted">No vehicles found</div>}
                      renderCell={(v, key) => {
                        switch (key) {
                          case 'class':    return <span className="font-semibold">{v.class}</span>
                          case 'location': return <span className="text-muted">{v.map || '—'}</span>
                          case 'chassis':
                            return (
                              <span className={v.chassis_durability < 0.3 ? 'text-danger' : 'text-muted'}>
                                {Math.round(v.chassis_durability * 100)}%
                              </span>
                            )
                          case 'name':     return <span className="text-muted">{v.vehicle_name || '—'}</span>
                          case 'type':
                            return (
                              <div className="flex gap-1">
                                {v.is_backup    && <Chip size="sm" color="accent"  variant="soft">Backup</Chip>}
                                {v.is_recovered && <Chip size="sm" color="warning" variant="soft">Recovered</Chip>}
                              </div>
                            )
                        }
                      }}
                    />
                  </div>
                </div>
              )}
            </Modal.Body>
          </Modal.Dialog>
        </Modal.Container>
      </Modal.Backdrop>
    </Modal>
  )
}
