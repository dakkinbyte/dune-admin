import type React from 'react'
import { Input } from '@heroui/react'

interface FieldInputProps {
  value: string
  onChange: (v: string) => void
  placeholder?: string
  type?: 'text' | 'number' | 'password' | 'email' | 'url'
  className?: string
  ariaLabel?: string
  isDisabled?: boolean
}

export const FieldInput: React.FC<FieldInputProps> = ({
  value,
  onChange,
  placeholder,
  type = 'text',
  className,
  ariaLabel,
  isDisabled,
}) => (
  <Input
    type={type}
    value={value}
    onChange={(e) => onChange(e.target.value)}
    placeholder={placeholder}
    aria-label={ariaLabel}
    disabled={isDisabled}
    className={className}
  />
)
