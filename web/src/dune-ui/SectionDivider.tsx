import type { ReactNode } from 'react'

type Props = {
  title: ReactNode
  /** Optional action buttons rendered on the right side of the divider. */
  children?: ReactNode
}

/**
 * Amber section title with a top border + padding above to separate it from
 * the preceding section. Matches the "Server Control" divider in
 * BattlegroupTab.
 */
export function SectionDivider({ title, children }: Props) {
  return (
    <div className="flex items-center gap-3 border-t border-[#9e6711]/30 pt-3 mt-3 shrink-0">
      <h3 className="text-base font-semibold text-accent flex-1 border-l-2 border-[#754d13] pl-2">{title}</h3>
      {children && <div className="flex items-center gap-2 shrink-0">{children}</div>}
    </div>
  )
}
