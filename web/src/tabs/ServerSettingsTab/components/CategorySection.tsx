import { Fragment } from 'react'
import type React from 'react'
import { useTranslation } from 'react-i18next'
import { Button } from '@heroui/react'
import type { ServerSetting } from '../../../api/client'
import { Panel, SectionLabel, Icon } from '../../../dune-ui'
import { SettingRow } from './SettingRow'
import { CATEGORY_ICONS, CATEGORY_LABELS, USER_SOURCES } from '../constants'

interface CategorySectionProps {
  title: string
  description: string
  categories: [string, ServerSetting[]][]
  expandedCategory: string | null
  onToggle: (cat: string) => void
  searching: boolean
  pending: Map<string, string>
  onChange: (item: ServerSetting, value: string) => void
  onDelete: (item: ServerSetting) => Promise<void>
  isAmpManaged: (item: ServerSetting) => boolean
}

// CategorySection renders one labelled block (Advanced or Expert) of collapsible
// category cards. Empty sections render nothing.
export const CategorySection: React.FC<CategorySectionProps> = ({
  title, description, categories, expandedCategory, onToggle,
  searching, pending, onChange, onDelete, isAmpManaged,
}) => {
  const { t } = useTranslation()
  if (categories.length === 0) return null
  const pendingKey = (item: ServerSetting) => `${item.section}|${item.key}`

  return (
    <div>
      <SectionLabel>{title}</SectionLabel>
      <div className="text-xs text-muted mb-2">{description}</div>
      <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 gap-2 mt-2">
        {categories.map(([cat, catItems]) => {
          const isOpen = searching || expandedCategory === cat
          const overrideCount = catItems.filter((i) =>
            i.layers.some((l) => USER_SOURCES.has(l.source)),
          ).length
          return (
            <Fragment key={cat}>
              <button
                onClick={() => onToggle(cat)}
                className={`flex items-center gap-2 rounded border px-3 py-2.5 text-left transition-colors ${
                  isOpen
                    ? 'bg-accent/15 border-accent/60 text-foreground'
                    : 'bg-surface border-border/60 hover:bg-surface-secondary hover:border-border text-foreground/90'
                }`}
              >
                <Icon
                  name={CATEGORY_ICONS[cat] ?? 'sliders'}
                  className={`w-4 h-4 shrink-0 ${isOpen ? 'text-accent' : 'text-muted'}`}
                />
                <div className="flex-1 min-w-0">
                  <div className="text-sm font-medium truncate">{CATEGORY_LABELS[cat] ?? cat}</div>
                  <div className="text-xs text-muted">
                    {catItems.length === 1
                      ? t('server.settingCount_one', { count: catItems.length })
                      : t('server.settingCount_other', { count: catItems.length })}
                    {overrideCount > 0 && (
                      <span className="ml-1 text-warning">
                        {t('server.overriddenCount', { count: overrideCount })}
                      </span>
                    )}
                  </div>
                </div>
                <Icon
                  name={isOpen ? 'chevron-up' : 'chevron-down'}
                  className={`w-4 h-4 shrink-0 ${isOpen ? 'text-accent' : 'text-muted/50'}`}
                />
              </button>
              {isOpen && (
                <Panel className="col-span-full mt-1 mb-1">
                  <div className="flex items-center justify-between mb-2">
                    <SectionLabel>{CATEGORY_LABELS[cat] ?? cat}</SectionLabel>
                    {!searching && (
                      <Button
                        size="sm"
                        variant="ghost"
                        onPress={() => onToggle(cat)}
                        aria-label={t('server.collapseCategory')}
                      >
                        <Icon name="x" className="w-3.5 h-3.5" />
                      </Button>
                    )}
                  </div>
                  <div>
                    {catItems.map((item) => (
                      <SettingRow
                        key={`${item.section}|${item.key}`}
                        item={item}
                        ampManaged={isAmpManaged(item)}
                        pending={pending.get(pendingKey(item))}
                        onChange={(v) => onChange(item, v)}
                        onDelete={() => onDelete(item)}
                      />
                    ))}
                  </div>
                </Panel>
              )}
            </Fragment>
          )
        })}
      </div>
    </div>
  )
}
