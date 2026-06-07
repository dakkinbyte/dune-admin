/**
 * Compatibility shim — re-exports the item-data API from store.ts so existing
 * import sites (MarketTab/ItemDetail, GiveItemsModal) continue to work without
 * modification.
 */

export type { ItemEntry, ItemDataFile } from './store'
export { cdnBase, getItemData, getItemEntry } from './store'
