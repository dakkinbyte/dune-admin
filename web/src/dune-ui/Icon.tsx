import { Icon as IconifyIcon } from '@iconify/react'

type Props = {
  /** Lucide icon name (without the `lucide:` prefix), e.g. "refresh-cw". */
  name: string
  /** Optional size class — defaults to `size-4` (1rem square). */
  className?: string
}

/**
 * Thin wrapper around `@iconify/react` that defaults to the lucide icon set
 * and a sensible inline-text size. Use any lucide icon name from
 * https://lucide.dev/icons (kebab-case).
 */
export function Icon({ name, className = 'size-4' }: Props) {
  return <IconifyIcon icon={`lucide:${name}`} className={className} />
}
