type ItemEntry = {
  name?: string
  category?: string
  tier?: number
  rarity?: string
  is_gradeable?: boolean
  armor_value?: number
  mitigation?: Record<string, number>
}

type ItemDataFile = {
  items: Record<string, ItemEntry>
}

let cache: ItemDataFile | null = null
let fetchPromise: Promise<ItemDataFile> | null = null

export const cdnBase = (): string =>
  ((import.meta.env.VITE_CDN_BASE_URL as string) ?? 'https://assets.dune.layout.tools').replace(/\/$/, '')

export function getItemData(): Promise<ItemDataFile> {
  if (cache) return Promise.resolve(cache)
  if (fetchPromise) return fetchPromise
  fetchPromise = fetch(`${cdnBase()}/item-data.json`)
    .then((r) => r.json() as Promise<ItemDataFile>)
    .then((data) => {
      cache = data
      return data
    })
    .catch(() => {
      fetchPromise = null
      return { items: {} }
    })
  return fetchPromise
}

export async function getItemEntry(templateId: string): Promise<ItemEntry | null> {
  const data = await getItemData()
  return data.items[templateId] ?? null
}
