import type React from 'react'
import { useTranslation } from 'react-i18next'
import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer } from 'recharts'
import type { SessionRecord } from '../../../api/client'
import { SectionLabel } from '../../../dune-ui'

interface SessionChartProps {
  data: SessionRecord[]
}

type DayBucket = { date: string, minutes: number }

const WINDOW_DAYS = 14

/** Returns today's UTC date as YYYY-MM-DD. */
function todayUTC(): string {
  return new Date().toISOString().slice(0, 10)
}

/**
 * Aggregates session records into a fixed WINDOW_DAYS window ending today (UTC).
 * Days with no sessions are zero-filled so the chart always shows a contiguous
 * range rather than being centred on sparse data.
 */
function aggregate(records: SessionRecord[]): DayBucket[] {
  const minutesByDay = new Map<string, number>()
  for (const r of records) {
    const day = r.started_at.slice(0, 10)
    minutesByDay.set(day, (minutesByDay.get(day) ?? 0) + Math.round(r.duration_secs / 60))
  }

  const buckets: DayBucket[] = []
  const today = todayUTC()
  for (let i = WINDOW_DAYS - 1; i >= 0; i--) {
    const d = new Date(today + 'T12:00:00Z')
    d.setUTCDate(d.getUTCDate() - i)
    const date = d.toISOString().slice(0, 10)
    buckets.push({ date, minutes: minutesByDay.get(date) ?? 0 })
  }
  return buckets
}

function fmtDate(d: string): string {
  return new Date(d + 'T12:00:00Z').toLocaleDateString(undefined, { month: 'short', day: 'numeric' })
}

export const SessionChart: React.FC<SessionChartProps> = ({ data }) => {
  const { t } = useTranslation()
  const buckets = aggregate(data)

  if (data.length === 0) {
    return (
      <div>
        <SectionLabel>{t('players.detail.sessionHistory')}</SectionLabel>
        <p className="text-muted text-sm mt-2">
          {t('players.detail.sessionHistoryEmpty')}
        </p>
      </div>
    )
  }

  return (
    <div>
      <SectionLabel>{t('players.detail.sessionHistory')}</SectionLabel>
      <div className="mt-3 h-40">
        <ResponsiveContainer width="100%" height="100%">
          <BarChart data={buckets} margin={{ top: 4, right: 8, left: 8, bottom: 0 }}>
            <XAxis
              dataKey="date"
              tickFormatter={fmtDate}
              tick={{ fontSize: 11, fill: 'var(--muted)' }}
              tickLine={false}
              axisLine={false}
            />
            <YAxis
              unit="m"
              tick={{ fontSize: 11, fill: 'var(--muted)' }}
              tickLine={false}
              axisLine={false}
              width={36}
            />
            <Tooltip
              cursor={{ fill: 'var(--surface-hover)' }}
              formatter={(val) => [`${val as number}m`, t('players.detail.playtime')]}
              labelFormatter={(d) => fmtDate(String(d))}
              contentStyle={{
                background: 'var(--surface)',
                border: '1px solid var(--border)',
                borderRadius: 'var(--radius)',
                fontSize: 12,
              }}
            />
            <Bar dataKey="minutes" fill="var(--accent)" radius={[3, 3, 0, 0]} maxBarSize={32} />
          </BarChart>
        </ResponsiveContainer>
      </div>
    </div>
  )
}
