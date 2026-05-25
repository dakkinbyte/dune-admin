import type { ReactNode } from 'react'

type Props = {
  title: ReactNode
  /** Optional descriptive subtitle below the title. */
  subtitle?: ReactNode
  /** Action buttons / controls rendered on the right. */
  children?: ReactNode
}

/**
 * Top-of-page header: amber title (text-base) on the left, action slot on the
 * right. Matches the BattlegroupTab "Black Lagoon (sh-…) ↻ Refresh" pattern.
 */
export function PageHeader({ title, subtitle, children }: Props) {
  return (
    <div className="flex items-start justify-between gap-3 shrink-0">
      <div className="flex-1 min-w-0">
        <h2 className="text-base font-semibold text-accent truncate">{title}</h2>
        {subtitle && <p className="text-sm text-muted mt-0.5">{subtitle}</p>}
      </div>
      {children && <div className="flex items-center gap-2 shrink-0">{children}</div>}
    </div>
  )
}
