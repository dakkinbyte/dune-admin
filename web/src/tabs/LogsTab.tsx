import { useState, useEffect, useRef, useCallback } from 'react'
import { Button, Spinner, toast } from '@heroui/react'
import { api, getWsBase } from '../api/client'
import type { LogPod, CheatEntry } from '../api/client'
import { useStatus } from '../hooks/useStatus'

type ActiveView = 'pod' | 'cheats'

export default function LogsTab() {
  const connStatus = useStatus()
  const isDirect = connStatus?.connection_mode === 'direct'
  const [pods, setPods] = useState<LogPod[]>([])
  const [podsLoading, setPodsLoading] = useState(false)
  const [selectedPod, setSelectedPod] = useState<LogPod | null>(null)
  const [connected, setConnected] = useState(false)
  const [autoScroll, setAutoScroll] = useState(true)
  const [displayLines, setDisplayLines] = useState<string[]>([])
  const [activeView, setActiveView] = useState<ActiveView>('pod')
  const [cheats, setCheats] = useState<CheatEntry[]>([])
  const [cheatsLoading, setCheatsLoading] = useState(false)

  const wsRef = useRef<WebSocket | null>(null)
  const linesRef = useRef<string[]>([])
  const flushTimerRef = useRef<ReturnType<typeof setInterval> | null>(null)
  const logContainerRef = useRef<HTMLPreElement | null>(null)

  // Load pods on mount
  useEffect(() => {
    setPodsLoading(true)
    api.logs.pods()
      .then(setPods)
      .catch((e: unknown) => {
        const msg = e instanceof Error ? e.message : String(e)
        toast.danger(`Failed to load pods: ${msg}`)
      })
      .finally(() => setPodsLoading(false))
  }, [])

  // Flush log lines to display every 200ms
  const startFlush = useCallback(() => {
    if (flushTimerRef.current) return
    flushTimerRef.current = setInterval(() => {
      if (linesRef.current.length > 0) {
        setDisplayLines(prev => {
          const combined = [...prev, ...linesRef.current]
          // Keep last 5000 lines
          return combined.length > 5000 ? combined.slice(combined.length - 5000) : combined
        })
        linesRef.current = []
      }
    }, 200)
  }, [])

  const stopFlush = useCallback(() => {
    if (flushTimerRef.current) {
      clearInterval(flushTimerRef.current)
      flushTimerRef.current = null
    }
  }, [])

  // Auto-scroll
  useEffect(() => {
    if (autoScroll && logContainerRef.current) {
      logContainerRef.current.scrollTop = logContainerRef.current.scrollHeight
    }
  }, [displayLines, autoScroll])

  const connectPod = useCallback((pod: LogPod) => {
    // Close existing connection
    if (wsRef.current) {
      wsRef.current.close()
      wsRef.current = null
    }
    stopFlush()
    linesRef.current = []
    setDisplayLines([])
    setConnected(false)
    setSelectedPod(pod)
    setActiveView('pod')

    const url = `${getWsBase()}/logs/stream?ns=${encodeURIComponent(pod.namespace)}&pod=${encodeURIComponent(pod.name)}`
    const ws = new WebSocket(url)
    wsRef.current = ws

    ws.onopen = () => {
      setConnected(true)
      startFlush()
    }

    ws.onmessage = (event: MessageEvent) => {
      linesRef.current.push(event.data as string)
    }

    ws.onerror = () => {
      toast.danger('WebSocket error')
    }

    ws.onclose = () => {
      setConnected(false)
      stopFlush()
      // Flush remaining lines
      if (linesRef.current.length > 0) {
        setDisplayLines(prev => [...prev, ...linesRef.current])
        linesRef.current = []
      }
    }
  }, [startFlush, stopFlush])

  const disconnect = useCallback(() => {
    if (wsRef.current) {
      wsRef.current.close()
      wsRef.current = null
    }
    stopFlush()
    setConnected(false)
  }, [stopFlush])

  // Cleanup on unmount
  useEffect(() => {
    return () => {
      disconnect()
    }
  }, [disconnect])

  const exportLogs = () => {
    const content = displayLines.join('\n')
    const blob = new Blob([content], { type: 'text/plain' })
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = `${selectedPod?.name ?? 'logs'}-${new Date().toISOString()}.txt`
    a.click()
    URL.revokeObjectURL(url)
  }

  const loadCheats = async () => {
    setCheatsLoading(true)
    try {
      setCheats(await api.logs.cheats())
    } catch (e: unknown) {
      toast.danger(e instanceof Error ? e.message : String(e))
    } finally {
      setCheatsLoading(false)
    }
  }

  const handleSelectCheats = () => {
    setSelectedPod(null)
    setActiveView('cheats')
    loadCheats()
  }

  return (
    <div className="flex h-full overflow-hidden">
      {/* Pod list */}
      <div
        className="w-56 shrink-0 flex flex-col gap-1 p-2 overflow-y-auto"
        style={{ background: 'var(--color-surface)', borderRight: '1px solid #2a2418' }}
      >
        <div className="flex items-center justify-between px-2 py-1 mb-1">
          <span className="text-xs font-semibold uppercase" style={{ color: 'var(--color-text-dim)' }}>{isDirect ? 'Log Files' : 'Pods'}</span>
          <Button
            size="sm"
            variant="ghost"
            isDisabled={podsLoading}
            onPress={() => {
              setPodsLoading(true)
              api.logs.pods()
                .then(setPods)
                .catch(() => { /* ignore */ })
                .finally(() => setPodsLoading(false))
            }}
          >
            {podsLoading ? <Spinner size="sm" color="current" /> : '↻'}
          </Button>
        </div>

        {/* Cheats entry */}
        <button
          onClick={handleSelectCheats}
          className="text-left px-2 py-1.5 rounded text-xs transition-colors"
          style={{
            background: activeView === 'cheats' ? 'var(--color-primary)' : 'transparent',
            color: activeView === 'cheats' ? '#fff' : 'var(--color-text)',
            marginBottom: '4px',
          }}
        >
          <div className="font-semibold">Cheats (7d)</div>
          <div className="text-[10px] opacity-60">Anti-cheat log</div>
        </button>

        <div style={{ borderBottom: '1px solid #2a2418', marginBottom: '4px' }} />

        {pods.length === 0 && !podsLoading && (
          <p className="text-xs px-2" style={{ color: 'var(--color-text-dim)' }}>{isDirect ? 'No log files found' : 'No pods found'}</p>
        )}
        {pods.map(pod => (
          <button
            key={`${pod.namespace}/${pod.name}`}
            onClick={() => connectPod(pod)}
            className="text-left px-2 py-1.5 rounded text-xs transition-colors"
            style={{
              background: activeView === 'pod' && selectedPod?.name === pod.name ? 'var(--color-primary)' : 'transparent',
              color: activeView === 'pod' && selectedPod?.name === pod.name ? '#fff' : 'var(--color-text)',
            }}
          >
            <div className="font-mono truncate">{pod.name}</div>
            <div className="text-[10px] opacity-60">{pod.namespace}</div>
          </button>
        ))}
      </div>

      {/* Main area */}
      <div className="flex-1 flex flex-col overflow-hidden">
        {activeView === 'cheats' ? (
          <>
            {/* Cheats toolbar */}
            <div
              className="flex items-center gap-3 px-4 py-2 shrink-0"
              style={{ background: 'var(--color-surface)', borderBottom: '1px solid #2a2418' }}
            >
              <span className="text-xs font-semibold" style={{ color: 'var(--color-primary)' }}>
                Anti-Cheat Events (7d)
              </span>
              <div className="flex-1" />
              <Button size="sm" variant="outline" onPress={loadCheats} isDisabled={cheatsLoading}>
                {cheatsLoading ? <Spinner size="sm" color="current" /> : '↻ Refresh'}
              </Button>
              <span className="text-xs" style={{ color: 'var(--color-text-dim)' }}>
                {cheats.length} events
              </span>
            </div>

            {/* Cheats table */}
            <div style={{ flex: 1, minHeight: 0, overflowY: 'auto', background: '#0a0806' }}>
              {cheatsLoading ? (
                <div className="flex justify-center py-12">
                  <Spinner size="lg" />
                </div>
              ) : cheats.length === 0 ? (
                <p className="text-xs p-4" style={{ color: 'var(--color-text-dim)' }}>
                  No cheat events found in the last 7 days.
                </p>
              ) : (
                <table className="w-full text-xs">
                  <thead style={{ position: 'sticky', top: 0, zIndex: 1, background: '#1a1610' }}>
                    <tr style={{ borderBottom: '1px solid #2a2418' }}>
                      {['Time', 'Character', 'Cheat Type'].map(h => (
                        <th key={h} className="text-left px-4 py-2 font-semibold uppercase tracking-wide" style={{ color: 'var(--color-primary)' }}>
                          {h}
                        </th>
                      ))}
                    </tr>
                  </thead>
                  <tbody>
                    {cheats.map((entry, i) => {
                      const isSuspicious = /dup|negative/i.test(entry.cheat_type)
                      return (
                        <tr key={i} style={{ borderBottom: '1px solid #1a1610', background: i % 2 === 0 ? '#0d0b07' : '#0f0d09' }}>
                          <td className="px-4 py-1.5 font-mono" style={{ color: 'var(--color-text-dim)', whiteSpace: 'nowrap' }}>
                            {entry.event_time}
                          </td>
                          <td className="px-4 py-1.5" style={{ color: 'var(--color-text)' }}>
                            {entry.character_name}
                          </td>
                          <td className="px-4 py-1.5 font-mono" style={{ color: isSuspicious ? '#e88' : 'var(--color-text)' }}>
                            {entry.cheat_type}
                          </td>
                        </tr>
                      )
                    })}
                  </tbody>
                </table>
              )}
            </div>
          </>
        ) : (
          <>
            {/* Log toolbar */}
            <div
              className="flex items-center gap-3 px-4 py-2 shrink-0"
              style={{ background: 'var(--color-surface)', borderBottom: '1px solid #2a2418' }}
            >
              <div className="flex items-center gap-2 text-xs">
                <div
                  className="w-2 h-2 rounded-full"
                  style={{ background: connected ? 'var(--color-success)' : '#555' }}
                />
                <span style={{ color: 'var(--color-text-dim)' }}>
                  {connected ? `Connected to ${selectedPod?.name}` : selectedPod ? 'Disconnected' : 'Select a pod'}
                </span>
              </div>
              <div className="flex-1" />
              <label className="flex items-center gap-1.5 text-xs cursor-pointer" style={{ color: 'var(--color-text-dim)' }}>
                <input
                  type="checkbox"
                  checked={autoScroll}
                  onChange={e => setAutoScroll(e.target.checked)}
                  className="w-3 h-3"
                />
                Auto-scroll
              </label>
              {selectedPod && connected && (
                <Button size="sm" variant="danger-soft" onPress={disconnect}>
                  Stop
                </Button>
              )}
              {selectedPod && !connected && (
                <Button size="sm" variant="outline" onPress={() => connectPod(selectedPod)}>
                  Reconnect
                </Button>
              )}
              {displayLines.length > 0 && (
                <Button size="sm" variant="ghost" onPress={exportLogs}>
                  Export
                </Button>
              )}
              {displayLines.length > 0 && (
                <Button
                  size="sm"
                  variant="ghost"
                  onPress={() => { setDisplayLines([]); linesRef.current = [] }}
                >
                  Clear
                </Button>
              )}
              <span className="text-xs" style={{ color: 'var(--color-text-dim)' }}>
                {displayLines.length} lines
              </span>
            </div>

            {/* Log output */}
            <pre
              ref={logContainerRef}
              className="flex-1 overflow-auto p-4 text-xs font-mono"
              style={{
                background: '#0a0806',
                color: '#a8d8a8',
                margin: 0,
                whiteSpace: 'pre-wrap',
                wordBreak: 'break-all',
              }}
            >
              {displayLines.length === 0
                ? (selectedPod
                  ? (connected ? 'Waiting for log lines...' : 'Disconnected.')
                  : isDirect ? 'Select a log file from the left panel to start streaming.' : 'Select a pod from the left panel to start streaming logs.')
                : displayLines.join('\n')
              }
            </pre>
          </>
        )}
      </div>
    </div>
  )
}
