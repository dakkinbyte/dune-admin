import type { ReactNode } from 'react'

type CardProps = { children: ReactNode; className?: string }

type ItemProps = {
  label: ReactNode
  value: ReactNode
  /** Optional explicit value text color (e.g. phase status color). */
  valueColor?: string
}

/**
 * Bordered, slightly-elevated label/value row card — the "Phase Reconciling
 * | Database Ready" health row pattern from BattlegroupTab.
 */
function InfoCardRoot({ children, className = '' }: CardProps) {
  return (
    <div
      className={
        'flex items-center gap-6 rounded-md px-4 py-3 text-sm shrink-0 ' +
        // Recessed look — only slightly elevated from the page bg, with a
        // hairline border. Matches the BattlegroupTab "Phase/Database" row.
        'bg-surface border border-border/60 ' +
        className
      }
    >
      {children}
    </div>
  )
}

function InfoCardItem({ label, value, valueColor }: ItemProps) {
  return (
    <div className="flex items-center gap-2">
      <span className="text-muted">{label}</span>
      <span className="font-semibold" style={valueColor ? { color: valueColor } : undefined}>
        {value}
      </span>
    </div>
  )
}

export const InfoCard = Object.assign(InfoCardRoot, { Item: InfoCardItem })
