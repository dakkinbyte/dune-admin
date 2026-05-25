import { Chip } from '@heroui/react'
import type { ReactNode } from 'react'

export type StatusKind = 'success' | 'warning' | 'danger' | 'accent' | 'default'

type Props = {
  kind?: StatusKind
  children: ReactNode
}

/**
 * Phase / status pill wrapping HeroUI Chip with our `soft` variant default
 * and dune-aligned color palette.
 */
export function StatusChip({ kind = 'default', children }: Props) {
  return (
    <Chip size="sm" color={kind} variant="soft">
      {children}
    </Chip>
  )
}
