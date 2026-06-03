import { Spinner } from '@heroui/react'

type Props = {
  /** Vertical padding size. Defaults to 'lg' (py-12). */
  size?: 'sm' | 'md' | 'lg'
  /** Fill available height with flex-1 (use inside a flex column). */
  fill?: boolean
  className?: string
}

const PAD: Record<NonNullable<Props['size']>, string> = {
  sm: 'py-4',
  md: 'py-8',
  lg: 'py-12',
}

/**
 * Standard centered loading spinner. Use for full-tab / full-section loads so
 * every tab shows the same loading treatment.
 */
export function LoadingState({ size = 'lg', fill = false, className = '' }: Props) {
  return (
    <div className={`flex justify-center ${PAD[size]} ${fill ? 'flex-1' : ''} ${className}`}>
      <Spinner size="lg" />
    </div>
  )
}
