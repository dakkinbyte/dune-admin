import type { ReactNode } from 'react'

/**
 * Small uppercase amber label — sub-section heading inside a Panel.
 * Pairs with [[PageHeader]] (top-level) and [[SectionDivider]] (mid-level).
 */
export function SectionLabel({ children }: { children: ReactNode }) {
  return (
    <h4 className="text-xs font-semibold uppercase tracking-widest text-accent border-l-2 border-[#754d13] pl-2">
      {children}
    </h4>
  )
}
