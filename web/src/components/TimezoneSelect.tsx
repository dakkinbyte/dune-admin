import type React from 'react'
import { useTranslation } from 'react-i18next'

// IANA timezone names from the browser when available (Chrome 99+/modern), with
// a small fallback for older runtimes. Computed once at module load.
function tzList(): string[] {
  const fn = (Intl as { supportedValuesOf?: (k: string) => string[] }).supportedValuesOf
  try {
    if (typeof fn === 'function') return fn('timeZone')
  }
  catch { /* fall through to fallback */ }
  return [
    'UTC', 'America/New_York', 'America/Chicago', 'America/Denver', 'America/Los_Angeles',
    'America/Sao_Paulo', 'Europe/London', 'Europe/Berlin', 'Europe/Paris', 'Europe/Moscow',
    'Asia/Tokyo', 'Asia/Shanghai', 'Asia/Kolkata', 'Australia/Sydney',
  ]
}

const ZONES = tzList()

// TimezoneSelect is a native dropdown of IANA timezones with an empty "host
// local" option (the backend treats "" as the server's local time). Native
// <select> gives free type-to-search over the ~400-entry list.
export const TimezoneSelect: React.FC<{
  value: string
  onChange: (v: string) => void
  className?: string
}> = ({ value, onChange, className }) => {
  const { t } = useTranslation()
  return (
    <select
      value={value}
      onChange={(e) => onChange(e.target.value)}
      aria-label={t('common.timezone')}
      className={`bg-surface text-foreground border border-border rounded px-2 py-1 text-sm ${className ?? ''}`}
    >
      <option value="">{t('common.tzHostLocal')}</option>
      {ZONES.map((z) => <option key={z} value={z}>{z}</option>)}
    </select>
  )
}
