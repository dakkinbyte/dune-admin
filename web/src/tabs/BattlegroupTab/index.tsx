import { useState, useEffect, useCallback } from 'react'
import { Button, Spinner, toast } from '@heroui/react'
import { api } from '../../api/client'
import type { BackupFile } from '../../api/client'
import { PageHeader, InfoCard, SectionDivider, Icon } from '../../dune-ui'

import { phaseColor } from './helpers'
import { ACTIONS, INIT_WARN_MS, type ActionDef, type DetailedStatus } from './types'
import { ServersTable } from './ServersTable'
import { ConfirmDialog } from './modals/ConfirmDialog'
import { CommandOutputModal } from './modals/CommandOutputModal'
import { RestoreModal } from './modals/RestoreModal'

export default function BattlegroupTab() {
  const [status, setStatus] = useState<DetailedStatus | null>(null)
  const [statusLoading, setStatusLoading] = useState(false)

  // Command lifecycle
  const [runningCmd, setRunningCmd] = useState<string | null>(null)
  const [cmdOutput, setCmdOutput] = useState<string | null>(null)
  const [cmdDone, setCmdDone] = useState(false)
  const [confirmCmd, setConfirmCmd] = useState<ActionDef | null>(null)
  const [startedAt, setStartedAt] = useState<number | null>(null)
  const [lastBackupFile, setLastBackupFile] = useState<string | null>(null)

  // Restore modal
  const [showRestore, setShowRestore] = useState(false)
  const [backupFiles, setBackupFiles] = useState<BackupFile[]>([])
  const [backupFilesLoading, setBackupFilesLoading] = useState(false)

  const fetchStatus = useCallback(async () => {
    setStatusLoading(true)
    try {
      const res = await api.battlegroup.status() as unknown as DetailedStatus
      setStatus(res)
    } catch (e: unknown) {
      toast.danger(`Status failed: ${e instanceof Error ? e.message : String(e)}`)
    } finally {
      setStatusLoading(false)
    }
  }, [])

  useEffect(() => { fetchStatus() }, [fetchStatus])

  // Re-render when init-warning window expires
  const [, forceRender] = useState(0)
  useEffect(() => {
    if (startedAt === null) return
    const remaining = INIT_WARN_MS - (Date.now() - startedAt)
    if (remaining <= 0) { setStartedAt(null); return }
    const t = setTimeout(() => { setStartedAt(null); forceRender(n => n + 1) }, remaining)
    return () => clearTimeout(t)
  }, [startedAt])

  const isInitializing = startedAt !== null && (Date.now() - startedAt) < INIT_WARN_MS

  const runCmd = async (action: ActionDef) => {
    setConfirmCmd(null)
    setRunningCmd(action.label)
    setCmdOutput(null)
    setCmdDone(false)
    try {
      const res = await api.battlegroup.exec(action.cmd)
      setCmdOutput(res.output || '(no output)')
      setCmdDone(true)
      if (action.cmd === 'start' || action.cmd === 'restart') setStartedAt(Date.now())
      if (action.cmd === 'backup') {
        const match = (res.output || '').match(/database-dumps\/[^/]+\/([^\s]+\.backup)/)
        if (match) setLastBackupFile(match[1])
      }
      toast.success(`${action.label} completed`)
      fetchStatus()
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : String(e)
      setCmdOutput(`Error: ${msg}`)
      setCmdDone(true)
      toast.danger(`${action.label} failed: ${msg}`)
    }
  }

  const openRestore = () => {
    setBackupFilesLoading(true)
    setBackupFiles([])
    setShowRestore(true)
    api.battlegroup.backupFiles()
      .then(setBackupFiles)
      .catch(() => toast.danger('Could not load backup files'))
      .finally(() => setBackupFilesLoading(false))
  }

  const bg = status?.battlegroup
  const servers = status?.servers ?? []

  return (
    <div className="flex flex-col h-full gap-3 min-h-0">

      {/* ── Overview ─────────────────────────────────────────────────── */}
      <PageHeader title={bg ? `${bg.title} (${bg.name})` : 'Battlegroup Status'}>
        <Button size="sm" variant="ghost" onPress={fetchStatus} isDisabled={statusLoading}>
          {statusLoading
            ? <Spinner size="sm" color="current" />
            : <><Icon name="refresh-cw" /> Refresh</>}
        </Button>
      </PageHeader>

      {bg && (
        <InfoCard>
          <InfoCard.Item label="Phase"    value={bg.phase || '—'}    valueColor={phaseColor(bg.phase)} />
          <InfoCard.Item label="Database" value={bg.database || '—'} valueColor={phaseColor(bg.database)} />
        </InfoCard>
      )}

      {isInitializing && (
        <div className="rounded-[var(--radius)] px-3 py-2 text-sm flex items-center gap-2 bg-warning/10 text-warning border border-warning/40 shrink-0">
          <Icon name="triangle-alert" />
          <span>Server just started — game servers may still be initializing (~2 min).</span>
        </div>
      )}

      <div className="flex-1 min-h-0 flex flex-col">
        {statusLoading && !status ? (
          <div className="flex items-center gap-2 py-4 text-muted">
            <Spinner size="sm" color="current" />
            <span className="text-sm">Loading status...</span>
          </div>
        ) : (
          <ServersTable
            servers={servers}
            isInitializing={isInitializing}
            emptyMessage={status ? 'No game servers found.' : 'Click Refresh to load status.'}
          />
        )}
      </div>

      {/* ── Server Control ───────────────────────────────────────────── */}
      <SectionDivider title="Server Control" />
      <div className="flex flex-wrap gap-2 shrink-0">
        {ACTIONS.map(action => (
          <Button
            key={action.cmd}
            variant={action.danger ? 'danger-soft' : 'outline'}
            onPress={() => setConfirmCmd(action)}
            isDisabled={runningCmd !== null}
            size="sm"
          >
            {action.label}
          </Button>
        ))}
        <Button variant="danger-soft" size="sm" isDisabled={runningCmd !== null} onPress={openRestore}>
          Restore
        </Button>
      </div>

      {/* ── Modals ───────────────────────────────────────────────────── */}
      <ConfirmDialog
        action={confirmCmd}
        onConfirm={runCmd}
        onClose={() => setConfirmCmd(null)}
      />
      <CommandOutputModal
        runningCmd={runningCmd}
        cmdOutput={cmdOutput}
        cmdDone={cmdDone}
        lastBackupFile={lastBackupFile}
        onClose={() => { setRunningCmd(null); setCmdOutput(null) }}
      />
      <RestoreModal
        open={showRestore}
        backupFiles={backupFiles}
        backupFilesLoading={backupFilesLoading}
        setBackupFiles={setBackupFiles}
        onClose={() => setShowRestore(false)}
        onRestoreComplete={output => {
          setCmdOutput(output)
          setCmdDone(true)
          setRunningCmd('Restore')
          setShowRestore(false)
        }}
      />
    </div>
  )
}
