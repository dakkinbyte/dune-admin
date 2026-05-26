import { useState } from 'react'
import { Button, InputGroup, TextField } from '@heroui/react'
import { Icon } from '../../../dune-ui'

type Props = {
  items: string[] | null | undefined
  onChange: (items: string[]) => void
}

export default function DisabledItemsManager({ items, onChange }: Props) {
  const [input, setInput] = useState('')
  const safeItems = items ?? []

  const add = () => {
    const val = input.trim()
    if (!val || safeItems.includes(val)) return
    onChange([...safeItems, val])
    setInput('')
  }

  const remove = (item: string) => {
    onChange(safeItems.filter(i => i !== item))
  }

  return (
    <div className="flex flex-col gap-2">
      <div className="flex gap-2">
        <TextField aria-label="Template ID to disable" className="flex-1">
          <InputGroup>
            <InputGroup.Input
              value={input}
              onChange={e => setInput(e.target.value)}
              placeholder="Template ID (e.g. Radiation_Suit)"
              onKeyDown={e => { if (e.key === 'Enter') add() }}
            />
          </InputGroup>
        </TextField>
        <Button size="sm" variant="outline" onPress={add}>
          <Icon name="plus" /> Add
        </Button>
      </div>
      {safeItems.length === 0 ? (
        <p className="text-xs text-muted">No items disabled.</p>
      ) : (
        <div className="flex flex-wrap gap-1.5 max-h-32 overflow-y-auto">
          {safeItems.map(item => (
            <span
              key={item}
              className="flex items-center gap-1 text-xs font-mono bg-surface border border-border rounded px-2 py-0.5"
            >
              {item}
              <button
                className="text-muted hover:text-danger"
                onClick={() => remove(item)}
                aria-label={`Remove ${item}`}
              >
                <Icon name="x" />
              </button>
            </span>
          ))}
        </div>
      )}
    </div>
  )
}
