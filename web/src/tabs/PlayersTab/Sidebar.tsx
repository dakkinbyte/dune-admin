import { SIDEBAR_ITEMS, type Sidebar as SidebarKey } from './types'

interface Props {
  active: SidebarKey
  onSelect: (key: SidebarKey) => void
}

export function Sidebar({ active, onSelect }: Props) {
  return (
    <div className="w-40 shrink-0 flex flex-col gap-1 rounded-lg p-2 bg-surface border border-border">
      {SIDEBAR_ITEMS.map(item => {
        const isActive = active === item.key
        return (
          <button
            key={item.key}
            onClick={() => onSelect(item.key)}
            className={
              'text-left px-3 py-2 rounded text-sm transition-colors ' +
              (isActive
                ? 'bg-accent text-accent-foreground font-semibold'
                : 'text-foreground hover:bg-surface-hover')
            }
          >
            {item.label}
          </button>
        )
      })}
    </div>
  )
}
