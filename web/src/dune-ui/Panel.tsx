import type { ReactNode } from 'react'

type Props = {
  children: ReactNode
  className?: string
}

/**
 * Elevated bordered card. Use for content groups like the Progression Unlock
 * sub-panels in PlayerActionsModal.
 */
export function Panel({ children, className = '' }: Props) {
  return (
    <div
      className={
        'rounded-md p-4 flex flex-col gap-2 ' +
        'bg-surface-secondary border border-border ' +
        className
      }
    >
      {children}
    </div>
  )
}
