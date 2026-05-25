/**
 * Pre-load the full lucide icon collection so `<Icon icon="lucide:..." />`
 * works offline without runtime CDN fetches. Bundle cost: ~500KB gzipped.
 * If that becomes a problem, switch to per-icon imports via `addIcon`.
 */
import { addCollection } from '@iconify/react'
import lucide from '@iconify-json/lucide/icons.json'

addCollection(lucide)
