import { useState, useEffect, useCallback, useMemo, useRef } from 'react'
import { useTranslation } from 'react-i18next'
import { Button, Select, ListBox, SearchField, Spinner, toast } from '@heroui/react'
import { MapContainer, ImageOverlay, CircleMarker, Marker, Tooltip, useMapEvents, useMap } from 'react-leaflet'
import L from 'leaflet'
import { CRS, type LatLngBoundsExpression } from 'leaflet'
import 'leaflet/dist/leaflet.css'
import { api, ApiError } from '../api/client'
import type { MapMarker, Player } from '../api/client'
import { ConfirmDialog, Icon, PageHeader, Panel, SectionLabel } from '../dune-ui'
import { useAutoRefresh } from '../hooks/useAutoRefresh'

// Map asset base URL — same CDN as item icons. Always serves from R2, even locally.
// Override with VITE_CDN_BASE_URL to point at a different host (e.g. local R2 dev proxy).
const MAP_BASE = ((import.meta.env.VITE_CDN_BASE_URL as string) ?? 'https://assets.dune.layout.tools').replace(/\/$/, '')
const mapUrl = (path: string) => `${MAP_BASE}/${path}`

// Tile CDN — serves the zoom pyramid (z=0..4) for Hagga Basin and Deep Desert.
// URL scheme: /{tileId}/{cdnZ}/{cdnY}/{cdnX}.webp  (y before x — confirmed empirically)
const TILE_CDN = 'https://cdn.th.gl/dune-awakening/map-tiles'

// 4096×4096 coordinate space aligns with the CDN tile pyramid:
//   CDN_z = Leaflet_z + 3  →  z=-3 → CDN z=0 (1 tile), z=1 → CDN z=4 (16×16)
const IMG_W = 4096
const IMG_H = 4096
const IMAGE_BOUNDS: LatLngBoundsExpression = [[0, 0], [IMG_H, IMG_W]]
const POLL_MS = 30000

// Sprite sheet: 11 cols × 12 rows, each icon 64×64px
// Positions extracted from the reference tool's HTML (object-position / 64).
const SPRITE_URL = mapUrl('map-data/map-icons.webp')
const SPRITE_COLS = 11
const SPRITE_ROWS = 12
const SPRITE_CELL = 64

// (col, row) exact positions from the reference tool — do not guess.
const ICON_POS: Record<string, [number, number]> = {
  // Loot / Items
  basic: [3, 0], vbasic: [3, 0], wbasic: [3, 0], ebasic: [3, 0], rbasic: [3, 0], srbasic: [3, 0],
  rare: [1, 0], vrare: [1, 0], wrare: [1, 0], drare: [1, 0],
  ultra_rare: [1, 1],
  small_ultra_rare: [6, 0],
  ammo: [2, 1], vammo: [2, 1], wammo: [2, 1], uammo: [2, 1], dammo: [2, 1],
  medical: [3, 1],
  weapon: [9, 0],
  corpse: [2, 0], vcorpse: [2, 0], fcorpse: [2, 0],
  fuel: [1, 2], vfuel: [1, 2], wfuel: [1, 2], dfuel: [1, 2], ufuel: [1, 2], owfuel: [1, 2],
  contract: [8, 0],
  refinery: [4, 3],
  water_tank: [1, 3],
  buried_treasure: [4, 9],
  treasure_loot_container: [3, 0],
  // Locations
  cave: [0, 0],
  intel_point: [4, 1],
  enemy_camp: [4, 0],
  primitive: [5, 0], kirab_camp: [5, 0],
  shipwreck: [7, 0],
  trading_post: [9, 1],
  taxi: [4, 6],
  bank: [10, 6],
  discoverable: [6, 7],
  exploration: [9, 2],
  // Vehicles
  buggy: [2, 3], ebuggy: [2, 3],
  bike: [10, 2],
  // Trainers
  bene_gesserit_trainer: [1, 4],
  mentat: [9, 4],
  planetologist: [8, 2],
  swordmaster: [1, 5],
  trooper: [10, 1],
  // IDs / Keys
  blue_id_band: [6, 2],
  green_id_band: [0, 1],
  orange_id_band: [5, 2],
  purple_id_band: [10, 0],
  red_id_band: [5, 1],
  // Resources — large
  spice_field_small: [10, 7],
  spice_field_medium: [0, 8],
  spice_field_large: [1, 8],
  agave_seeds: [1, 9],
  azurite: [8, 8], azurite_pickup: [8, 8], // Copper Ore
  basalt: [5, 8], basalt_pickup: [5, 8],
  bauxite: [7, 8], bauxite_pickup: [7, 8], // Aluminium Ore
  dolomite: [10, 8], dolomite_pickup: [10, 8], // Carbon Ore
  erythrite: [0, 9], erythrite_pickup: [0, 9],
  fiber_plant: [6, 8], plant_fiber: [6, 8],
  fuel_cells: [5, 9],
  jasmium: [3, 9], jasmium_crystal: [3, 9],
  magnetite: [2, 9], magnetite_pickup: [2, 9], // Iron Ore
  primrose_field: [9, 7],
  rhyolite: [9, 8], rhyolite_pickup: [9, 8], // Granite Stone
  scrap_electronics: [7, 9],
  scrap_metal: [6, 9],
  stravidium: [4, 8],
  titanium_ore: [3, 8],
  // Vendors
  barkeep: [0, 7],
  base_vendor: [6, 6],
  landsraad_vendor: [2, 7],
  scrap_trader: [9, 6],
  spice_merchant: [7, 6],
  vehicle_vendor: [5, 6],
  water_seller: [8, 6],
  weapons_merchant: [1, 7],
  banker: [10, 6],
  // NPCs (by faction)
  atreides_npc: [3, 4],
  harkonnen_npc: [8, 4],
  fremen_npc: [0, 6],
  bene_gesserit_npc: [10, 5],
  choam_npc: [7, 5],
  bandits_npc: [3, 5],
  sardaukar_npc: [9, 5],
  smugglers_npc: [6, 5],
  spacing_guild_npc: [8, 5],
  unaffiliated_npc: [7, 1],
  // Landsraad houses
  alexin: [1, 6], argosaz: [0, 2], dyvetz: [7, 4], ecaz: [10, 4],
  hagal: [4, 4], hurata: [9, 3], imota: [5, 5], kenola: [3, 3],
  lindaren: [5, 4], maros: [8, 7], mikarrol: [4, 5], moritani: [6, 4],
  mutelli: [4, 7], novebruns: [8, 3], richese: [2, 4], sor: [2, 5],
  spinette: [2, 6], taligari: [0, 3], thorvald: [0, 5], tseida: [7, 3],
  varota: [3, 7], vernius: [0, 4], wallach: [5, 7], wayku: [7, 7], wydras: [8, 1],
  // Heatmap resource types — mapped to equivalent existing sprites
  aluminum_ore: [7, 8], // bauxite sprite
  copper_ore: [8, 8], // azurite sprite
  carbon_fiber: [10, 8], // dolomite sprite
  iron_ore: [2, 9], // magnetite sprite
  stone: [9, 8], // rhyolite sprite
  fiber: [6, 8], // fiber_plant sprite
  cistanche: [1, 9], // agave_seeds sprite (closest flora)
  saguaro_cactus: [1, 9], // agave_seeds sprite
  t6_resource_a: [4, 8], // stravidium sprite
  t6_resource_b: [3, 8], // titanium_ore sprite
  sandworm_territory: [4, 0], // enemy_camp sprite (danger zone)
  // No-underscore binary type variants
  enemycamp: [4, 0], enemyoutpost: [6, 1], enemylaboroutpost: [10, 3],
  wreck: [2, 2], tradingpost: [9, 1], sietch: [0, 2], ecolab: [7, 2],
  small_shipwreck: [7, 0], atreides: [3, 4], harkonnen: [8, 4], poi: [6, 7],
  // NPCs by faction
  npc_harkonnen: [8, 5], npc_atreides: [3, 5], npc_bandits: [3, 5],
  npc_unaffiliated: [7, 1], npc_choam: [7, 5], npc_fremen: [0, 6],
  npc_sardaukar: [9, 5], npc_smugglers: [6, 5], npc_spacingguild: [8, 5],
  // Trainers (no-underscore binary format)
  trainersswordmaster: [1, 5], trainersmentat: [9, 4], trainersbenegesserit: [1, 4],
  trainersplanetologist: [8, 2], trainerstrooper: [10, 1],
  // Vehicles (no-underscore)
  sandbike: [10, 2],
}

// Per-category dot colors for non-sprite fallback
const CAT_COLOR: Record<string, string> = {
  player: '#3b9dff', vehicle: '#5fd35a', base: '#e0a13a',
  resources: '#f5a623', locations: '#9b59b6', npcs: '#e74c3c',
  vendors: '#2ecc71', landsraad: '#e91e8c', static: '#7f8c8d',
  hazards: '#ff5020',
}

// Map spawn type → category

// Friendly display names for types
const TYPE_LABELS: Record<string, string> = {
  basic: 'Basic', vbasic: 'Basic', wbasic: 'Basic', ebasic: 'Basic', rbasic: 'Basic', srbasic: 'Basic',
  rare: 'Rare', vrare: 'Rare', wrare: 'Rare', drare: 'Rare',
  ultra_rare: 'Ultra Rare', ammo: 'Ammo', vammo: 'Ammo', wammo: 'Ammo', uammo: 'Ammo', dammo: 'Ammo',
  medical: 'Medical', weapon: 'Weapon', corpse: 'Corpse', vcorpse: 'Corpse', fcorpse: 'Corpse',
  fuel: 'Fuel', vfuel: 'Fuel', wfuel: 'Fuel', dfuel: 'Fuel', ufuel: 'Fuel', owfuel: 'Fuel',
  contract: 'Contract', refinery: 'Refinery', water_tank: 'Water Tank',
  treasure_loot_container: 'Loot Container',
  enemy_camp: 'Enemy Camp', primitive: 'Primitive Camp', kirab_camp: 'Kirab Camp',
  intel_point: 'Intel Point', buggy: 'Buggy', ebuggy: 'Buggy',
  spice_field_small: 'Small Spice', spice_field_medium: 'Medium Spice', spice_field_large: 'Large Spice',
  basalt: 'Basalt Stone', basalt_pickup: 'Basalt (Node)',
  fiber_plant: 'Plant Fiber', plant_fiber: 'Plant Fiber',
  bauxite: 'Aluminum Ore', bauxite_pickup: 'Aluminum (Node)',
  agave_seeds: 'Agave Seeds',
  erythrite: 'Erythrite Crystal', erythrite_pickup: 'Erythrite (Node)',
  jasmium: 'Jasmium Crystal', jasmium_crystal: 'Jasmium Crystal',
  scrap_electronics: 'Scrap Electronics', scrap_metal: 'Scrap Metal',
  fuel_cells: 'Fuel Cells',
  azurite: 'Copper Ore', azurite_pickup: 'Copper (Node)',
  dolomite: 'Carbon Ore', dolomite_pickup: 'Carbon (Node)',
  magnetite: 'Iron Ore', magnetite_pickup: 'Iron (Node)',
  rhyolite: 'Granite Stone', rhyolite_pickup: 'Granite (Node)',
  primrose_field: 'Primrose Field', stravidium: 'Stravidium', titanium_ore: 'Titanium',
  // Heatmap types
  aluminum_ore: 'Aluminum Ore', copper_ore: 'Copper Ore', carbon_fiber: 'Carbon Fiber',
  iron_ore: 'Iron Ore', stone: 'Stone', fiber: 'Plant Fiber',
  cistanche: 'Cistanche', saguaro_cactus: 'Saguaro Cactus',
  t6_resource_a: 'T6 Resource A', t6_resource_b: 'T6 Resource B',
  sandworm_territory: 'Sandworm Territory', buried_treasure: 'Buried Treasure',
  static: 'Static Object',
  // No-underscore binary types
  enemycamp: 'Enemy Camp', enemyoutpost: 'Enemy Outpost', enemylaboroutpost: 'Enemy Lab Outpost',
  cave: 'Cave', wreck: 'Wreck', tradingpost: 'Trading Post', sietch: 'Sietch',
  ecolab: 'Eco Lab', secret_door: 'Secret Door', shipwreck: 'Shipwreck',
  small_shipwreck: 'Small Shipwreck', atreides: 'Atreides', harkonnen: 'Harkonnen', poi: 'Point of Interest',
  npc_harkonnen: 'Harkonnen NPC', npc_atreides: 'Atreides NPC', npc_bandits: 'Bandits',
  npc_unaffiliated: 'Unaffiliated', npc_choam: 'CHOAM', npc_fremen: 'Fremen',
  npc_sardaukar: 'Sardaukar', npc_smugglers: 'Smugglers', npc_spacingguild: 'Spacing Guild',
  trainersswordmaster: 'Swordmaster', trainersmentat: 'Mentat', trainersbenegesserit: 'Bene Gesserit',
  trainersplanetologist: 'Planetologist', trainerstrooper: 'Trooper',
  purple_id_band: 'Purple ID Band', green_id_band: 'Green ID Band',
  red_id_band: 'Red ID Band', orange_id_band: 'Orange ID Band', blue_id_band: 'Blue ID Band',
  sandbike: 'Sandbike',
}

// Map types that should be merged (same visual/filter group)
const TYPE_MERGE_KEY: Record<string, string> = {
  vbasic: 'basic', wbasic: 'basic', ebasic: 'basic', rbasic: 'basic', srbasic: 'basic',
  vrare: 'rare', wrare: 'rare', drare: 'rare',
  vammo: 'ammo', wammo: 'ammo', uammo: 'ammo', dammo: 'ammo',
  vcorpse: 'corpse', fcorpse: 'corpse',
  vfuel: 'fuel', wfuel: 'fuel', dfuel: 'fuel', ufuel: 'fuel', owfuel: 'fuel',
  ebuggy: 'buggy',
  basalt_pickup: 'basalt',
  bauxite_pickup: 'bauxite',
  erythrite_pickup: 'erythrite',
  jasmium_crystal: 'jasmium',
  azurite_pickup: 'azurite',
  dolomite_pickup: 'dolomite',
  magnetite_pickup: 'magnetite',
  rhyolite_pickup: 'rhyolite',
  plant_fiber: 'fiber_plant',
}

function filterKey(type: string): string {
  return TYPE_MERGE_KEY[type] ?? type
}

type Bounds = { minX: number, maxX: number, minY: number, maxY: number, flipX?: boolean, flipY?: boolean }
type MapCfg = Bounds & {
  key: string
  label: string
  image?: string
  spawnFile?: string
  hasLiveData?: boolean
  tileId?: string
  depthFile?: string
}

const MAPS: MapCfg[] = [
  {
    key: 'HaggaBasin', label: 'Hagga Basin', image: 'hagga-basin.webp', spawnFile: 'hagga',
    tileId: 'survival_1-0c70ddebb3e41cf49915b22e103e94ed',
    depthFile: 'hagga-depth.webp',
    hasLiveData: true,
    minX: -437871, maxX: 350539, minY: -462011, maxY: 376267, flipY: true,
  },
  {
    key: 'DeepDesert', label: 'Deep Desert', image: 'deepdesert.webp', spawnFile: 'deepdesert',
    tileId: 'deepdesert_1-40f176fc4cce018dff08f3cd66b52f08',
    depthFile: 'deepdesert-depth.webp',
    hasLiveData: true,
    minX: -1300000, maxX: 1200000, minY: -1300000, maxY: 1200000,
  },
  {
    key: 'Arrakeen', label: 'Arrakeen', image: 'arrakeen.webp', spawnFile: 'arrakeen',
    hasLiveData: false,
    minX: -32000, maxX: 17000, minY: -10000, maxY: 9500, flipY: true,
  },
  {
    key: 'HarkoVillage', label: 'Harko Village', image: 'harko.webp', spawnFile: 'harko',
    hasLiveData: false,
    minX: -5000, maxX: 14500, minY: -5500, maxY: 32000,
  },
]

const CALIB_LS_KEY = 'dune_admin_livemap_calib'

type SpawnEntry = { type: string, label?: string, category: string, x: number, y: number, z?: number, density?: number }
type SpawnFile = { spawns: SpawnEntry[] }

// Heatmap world bounds per map key (CartographyMapLayerComponent meters × 100 = UE cm)
const HEATMAP_BOUNDS: Record<string, { minX: number, maxX: number, minY: number, maxY: number }> = {
  HaggaBasin: { minX: -457200, maxX: 355600, minY: -457200, maxY: 355600 },
  DeepDesert: { minX: -1270000, maxX: 1168400, minY: -1270000, maxY: 1168400 },
}

// Heatmap file prefix per map key
const HEATMAP_PREFIX: Record<string, string> = {
  HaggaBasin: 'hagga',
  DeepDesert: 'deepdesert',
}

// Maps heatmap type name → filter panel canonical key (from .raw spawn data via TYPE_MERGE_KEY).
// Heatmap uses descriptive names; .raw data uses mineral names — same resource, different labels.
const HEATMAP_TO_FILTER: Record<string, string> = {
  aluminum_ore: 'bauxite',
  copper_ore: 'azurite',
  carbon_fiber: 'dolomite',
  iron_ore: 'magnetite',
  stone: 'rhyolite',
  fiber: 'fiber_plant',
}
function heatmapFilterKey(type: string): string {
  return HEATMAP_TO_FILTER[type] ?? type
}

// CSS color per heatmap type — matches what build-map-heatmaps.py bakes into the PNGs
const HEATMAP_COLORS: Record<string, string> = {
  aluminum_ore: 'rgb(201,130,10)', copper_ore: 'rgb(184,115,51)',
  carbon_fiber: 'rgb(90,90,90)', iron_ore: 'rgb(130,130,145)',
  stone: 'rgb(160,145,120)', basalt: 'rgb(150,100,50)',
  scrap_metal: 'rgb(100,120,145)', fuel: 'rgb(255,200,50)',
  fiber: 'rgb(120,200,80)', cistanche: 'rgb(60,180,120)',
  saguaro_cactus: 'rgb(40,160,80)', primrose_field: 'rgb(200,200,60)',
  jasmium: 'rgb(180,100,220)', erythrite: 'rgb(220,60,60)',
  t6_resource_a: 'rgb(100,220,220)', t6_resource_b: 'rgb(60,180,220)',
  sandworm_territory: 'rgb(255,80,30)',
}

// Deep Desert zone grid: rows A(south)..I(north), columns 1(west)..9(east)
const DD_ROWS = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I']
const DD_COLS = [1, 2, 3, 4, 5, 6, 7, 8, 9]

// Types with non-empty heatmap PNGs per map
const HEATMAP_TYPES: Record<string, string[]> = {
  HaggaBasin: [
    'aluminum_ore', 'basalt', 'carbon_fiber', 'cistanche', 'copper_ore',
    'erythrite', 'fiber', 'fuel', 'iron_ore', 'jasmium',
    'primrose_field', 'saguaro_cactus', 'sandworm_territory', 'scrap_metal', 'stone',
  ],
  DeepDesert: [
    'aluminum_ore', 'basalt', 'carbon_fiber', 'copper_ore',
    'fiber', 'fuel', 'iron_ore',
    'sandworm_territory', 'scrap_metal', 'stone', 't6_resource_a', 't6_resource_b',
  ],
}

// ── Utility ──────────────────────────────────────────────────────────────────

function clamp01(v: number) {
  if (v < 0) return 0
  if (v > 1) return 1
  return v
}

function worldToLatLng(x: number, y: number, cfg: Bounds): [number, number] {
  const normX = (x - cfg.minX) / (cfg.maxX - cfg.minX)
  const normY = (y - cfg.minY) / (cfg.maxY - cfg.minY)
  const fracX = clamp01(cfg.flipX ? 1 - normX : normX)
  const fracYup = clamp01(cfg.flipY ? 1 - normY : normY)
  return [fracYup * IMG_H, fracX * IMG_W]
}

function latLngToWorld(lat: number, lng: number, cfg: Bounds): { x: number, y: number } {
  const fracX = lng / IMG_W
  const fracYup = lat / IMG_H
  const rawX = cfg.flipX ? 1 - fracX : fracX
  const rawY = cfg.flipY ? 1 - fracYup : fracYup
  return {
    x: rawX * (cfg.maxX - cfg.minX) + cfg.minX,
    y: rawY * (cfg.maxY - cfg.minY) + cfg.minY,
  }
}

type CalibPoint = { wx: number, wy: number, fracX: number, fracYup: number }

function solveBounds(pts: CalibPoint[]): Bounds | null {
  if (pts.length < 2) return null
  const a = pts[0]
  const b = pts[pts.length - 1]
  if (b.wx === a.wx || b.wy === a.wy || b.fracX === a.fracX || b.fracYup === a.fracYup) return null
  const sX = (b.fracX - a.fracX) / (b.wx - a.wx)
  const iX = a.fracX - sX * a.wx
  const sY = (b.fracYup - a.fracYup) / (b.wy - a.wy)
  const iY = a.fracYup - sY * a.wy
  const flipY = sY < 0
  const minX = -iX / sX
  const maxX = (1 - iX) / sX
  const R = flipY ? -1 / sY : 1 / sY
  const minY = flipY ? (iY - 1) * R : -iY * R
  return { minX, maxX, minY, maxY: minY + R, flipY }
}

function loadCalib(): Record<string, Bounds> {
  try {
    return JSON.parse(localStorage.getItem(CALIB_LS_KEY) ?? '{}') as Record<string, Bounds>
  }
  catch {
    return {}
  }
}

function InvalidateOnActive({ active }: { active: boolean }) {
  const map = useMap()
  useEffect(() => {
    if (active) {
      const id = setTimeout(() => {
        map.invalidateSize()
        map.fitBounds(IMAGE_BOUNDS)
      }, 50)
      return () => clearTimeout(id)
    }
  }, [active, map])
  return null
}

function MapClickCapture({ active, onPick }: { active: boolean, onPick: (lat: number, lng: number) => void }) {
  useMapEvents({
    click(e) {
      if (active) onPick(e.latlng.lat, e.latlng.lng)
    },
  })
  return null
}

// ── Sprite icon ───────────────────────────────────────────────────────────────

// SpriteIcon renders a single icon from the sprite sheet.
// size: desired display size in CSS px (default 22 = 0.35 × 64, matches reference tool).
function SpriteIcon({ type, size = 22 }: { type: string, size?: number }) {
  const pos = ICON_POS[type]
  if (!pos) return null
  const [col, row] = pos
  const scale = size / SPRITE_CELL
  const bw = SPRITE_COLS * SPRITE_CELL * scale
  const bh = SPRITE_ROWS * SPRITE_CELL * scale
  const bx = -(col * SPRITE_CELL * scale)
  const by = -(row * SPRITE_CELL * scale)
  return (
    <span
      className="inline-block shrink-0"
      style={{
        width: size,
        height: size,
        backgroundImage: `url(${SPRITE_URL})`,
        backgroundPosition: `${bx}px ${by}px`,
        backgroundSize: `${bw}px ${bh}px`,
        backgroundRepeat: 'no-repeat',
        imageRendering: 'pixelated',
      }}
    />
  )
}

// ── Canvas spawn layer ────────────────────────────────────────────────────────
// Renders all static spawn markers onto a single <canvas> element using
// drawImage from the sprite sheet. Handles 30k+ points at 60fps — orders of
// magnitude faster than per-marker DOM elements.

function SpawnCanvasLayer({
  spawns, effCfg, filter, heatmapMode,
}: {
  spawns: SpawnEntry[]
  effCfg: MapCfg
  filter: Record<string, boolean>
  heatmapMode: boolean
}) {
  const map = useMap()
  const canvasRef = useRef<HTMLCanvasElement | null>(null)
  const spriteRef = useRef<HTMLImageElement | null>(null)
  const spriteReady = useRef(false)

  // Pre-compute visible spawn list whenever inputs change
  const visible = useMemo(
    () => spawns.filter((s) => {
      if (!(filter[filterKey(s.type)] ?? false)) return false
      // When density overlay is on, hide all resource nodes — the heatmap conveys this
      if (heatmapMode && (s.category === 'resources' || s.category === 'hazards')) return false
      return true
    }),
    [spawns, filter, heatmapMode],
  )

  // Draw everything onto the canvas
  const draw = useCallback(() => {
    const canvas = canvasRef.current
    if (!canvas) return
    const mapSize = map.getSize()
    canvas.width = mapSize.x
    canvas.height = mapSize.y
    const ctx = canvas.getContext('2d')
    if (!ctx) return
    ctx.clearRect(0, 0, mapSize.x, mapSize.y)

    const sprite = spriteRef.current

    for (const s of visible) {
      const isDense = s.category === 'resources' || s.category === 'static'

      const [lat, lng] = worldToLatLng(s.x, s.y, effCfg)
      const pt = map.latLngToContainerPoint([lat, lng])

      // Viewport cull with padding
      if (pt.x < -32 || pt.x > mapSize.x + 32 || pt.y < -32 || pt.y > mapSize.y + 32) continue

      const typeKey = filterKey(s.type)
      const pos = ICON_POS[typeKey]
      const iconSize = isDense ? 20 : 28

      if (sprite && spriteReady.current && pos) {
        const [col, row] = pos
        ctx.drawImage(
          sprite,
          col * SPRITE_CELL, row * SPRITE_CELL,
          SPRITE_CELL, SPRITE_CELL,
          pt.x - iconSize / 2, pt.y - iconSize / 2,
          iconSize, iconSize,
        )
      }
      else {
        // Fallback colored dot
        ctx.beginPath()
        ctx.arc(pt.x, pt.y, isDense ? 3 : 5, 0, Math.PI * 2)
        ctx.fillStyle = CAT_COLOR[s.category] ?? '#888'
        ctx.globalAlpha = 0.65
        ctx.fill()
        ctx.globalAlpha = 1
      }
    }
  }, [map, visible, effCfg])

  // Mount canvas onto the map container (not a pane — we use containerPoint)
  useEffect(() => {
    const container = map.getContainer()
    const canvas = document.createElement('canvas')
    canvas.style.cssText = 'position:absolute;left:0;top:0;pointer-events:none;z-index:499'
    container.appendChild(canvas)
    canvasRef.current = canvas

    // Load sprite sheet once
    const img = new Image()
    img.src = SPRITE_URL
    img.onload = () => {
      spriteRef.current = img
      spriteReady.current = true
      draw()
    }

    return () => {
      canvas.remove()
      canvasRef.current = null
    }
  }, [map]) // eslint-disable-line react-hooks/exhaustive-deps

  // Redraw on every map move/zoom
  useEffect(() => {
    map.on('move zoom moveend zoomend viewreset resize', draw)
    draw()
    return () => {
      map.off('move zoom moveend zoomend viewreset resize', draw)
    }
  }, [map, draw])

  return null
}

// ── Heatmap density overlay ───────────────────────────────────────────────────
// Renders pre-baked 256×256 RGBA density PNGs over the map, one per resource type.
// Images are loaded lazily when first needed and cached for the session.
function HeatmapCanvasLayer({
  mapKey, effCfg, filter,
}: {
  mapKey: string
  effCfg: MapCfg
  filter: Record<string, boolean>
}) {
  const map = useMap()
  const canvasRef = useRef<HTMLCanvasElement | null>(null)
  const imageCache = useRef(new Map<string, HTMLImageElement | null>())
  const pendingRef = useRef(new Set<string>())

  const bounds = HEATMAP_BOUNDS[mapKey]
  const prefix = HEATMAP_PREFIX[mapKey]
  const types = useMemo(() => HEATMAP_TYPES[mapKey] ?? [], [mapKey])

  const draw = useCallback(() => {
    const canvas = canvasRef.current
    if (!canvas || !bounds) return
    const mapSize = map.getSize()
    canvas.width = mapSize.x
    canvas.height = mapSize.y
    const ctx = canvas.getContext('2d')
    if (!ctx) return
    ctx.clearRect(0, 0, mapSize.x, mapSize.y)

    // Map the heatmap grid extent to canvas coordinates.
    // For flipY maps (Hagga), minX/maxY → screen top-left; for others the draw height
    // is negative which flips the image vertically — both cases are handled correctly.
    const [tlLat, tlLng] = worldToLatLng(bounds.minX, bounds.maxY, effCfg)
    const [brLat, brLng] = worldToLatLng(bounds.maxX, bounds.minY, effCfg)
    const tl = map.latLngToContainerPoint([tlLat, tlLng])
    const br = map.latLngToContainerPoint([brLat, brLng])
    const dw = br.x - tl.x
    const dh = br.y - tl.y

    ctx.globalAlpha = 0.65
    for (const type of types) {
      if (!(filter[heatmapFilterKey(type)] ?? false)) continue
      const img = imageCache.current.get(type)
      if (img) ctx.drawImage(img, tl.x, tl.y, dw, dh)
    }
    ctx.globalAlpha = 1
  }, [map, bounds, effCfg, filter, types])

  // Lazily load PNGs for enabled types
  useEffect(() => {
    if (!prefix) return
    for (const type of types) {
      if (!(filter[heatmapFilterKey(type)] ?? false)) continue
      if (imageCache.current.has(type) || pendingRef.current.has(type)) continue
      pendingRef.current.add(type)
      const img = new Image()
      img.onload = () => {
        imageCache.current.set(type, img)
        pendingRef.current.delete(type)
        draw()
      }
      img.onerror = () => {
        imageCache.current.set(type, null)
        pendingRef.current.delete(type)
      }
      img.src = mapUrl(`map-data/${prefix}-heatmap-${type}.png`)
    }
  }, [filter, types, prefix, draw])

  useEffect(() => {
    const container = map.getContainer()
    const canvas = document.createElement('canvas')
    canvas.style.cssText = 'position:absolute;left:0;top:0;pointer-events:none;z-index:498'
    container.appendChild(canvas)
    canvasRef.current = canvas
    return () => {
      canvas.remove()
      canvasRef.current = null
    }
  }, [map])

  useEffect(() => {
    map.on('move zoom moveend zoomend viewreset resize', draw)
    draw()
    return () => {
      map.off('move zoom moveend zoomend viewreset resize', draw)
    }
  }, [map, draw])

  return null
}

// ── CDN tile layer ────────────────────────────────────────────────────────────
// CDN_z = Leaflet_z + 3.  maxNativeZoom=1 means Leaflet zoom > 1 reuses CDN z=4 tiles scaled up.
function MapTileLayer({ tileId }: { tileId: string }) {
  const map = useMap()

  useEffect(() => {
    const layer = new L.TileLayer('', {
      tileSize: 512,
      minZoom: -3,
      maxZoom: 4,
      maxNativeZoom: 1,
      noWrap: true,
      attribution: '',
    })

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    ;(layer as any).getTileUrl = (coords: L.Coords): string => {
      const cdnZ = Math.min(4, Math.max(0, coords.z + 3))
      // CRS.Simple with transformation (1,0,-1,0) inverts the y axis, so Leaflet tile y
      // indices are negative (e.g. -8..-1 at z_L=0 for an 8-tile-tall map).
      // CDN_y = 2^cdnZ + leaflet_y/scale  maps negative Leaflet y → positive CDN y [0, 2^cdnZ).
      const scale = Math.pow(2, coords.z + 3 - cdnZ)
      const cdnX = Math.floor(coords.x / scale)
      const cdnY = Math.floor(Math.pow(2, cdnZ) + coords.y / scale)
      const maxTile = Math.pow(2, cdnZ)
      if (cdnX < 0 || cdnX >= maxTile || cdnY < 0 || cdnY >= maxTile) return ''
      return `${TILE_CDN}/${tileId}/${cdnZ}/${cdnY}/${cdnX}.webp`
    }

    layer.addTo(map)
    return () => {
      layer.remove()
    }
  }, [map, tileId])

  return null
}

// ── Deep Desert zone grid (A1-I9) ─────────────────────────────────────────────
function ZoneGridLayer({ effCfg }: { effCfg: MapCfg }) {
  const map = useMap()
  const canvasRef = useRef<HTMLCanvasElement | null>(null)

  const draw = useCallback(() => {
    const canvas = canvasRef.current
    if (!canvas) return
    const mapSize = map.getSize()
    canvas.width = mapSize.x
    canvas.height = mapSize.y
    const ctx = canvas.getContext('2d')
    if (!ctx) return
    ctx.clearRect(0, 0, mapSize.x, mapSize.y)

    const b = { minX: effCfg.minX, maxX: effCfg.maxX, minY: effCfg.minY, maxY: effCfg.maxY }
    const cellW = (b.maxX - b.minX) / 9
    const cellH = (b.maxY - b.minY) / 9

    ctx.strokeStyle = 'rgba(255,255,255,0.25)'
    ctx.lineWidth = 1
    ctx.fillStyle = 'rgba(255,255,255,0.45)'
    ctx.font = '11px sans-serif'
    ctx.textAlign = 'center'
    ctx.textBaseline = 'middle'

    // Draw grid lines and labels
    for (let ci = 0; ci <= 9; ci++) {
      const x = b.minX + ci * cellW
      const [latB, lngB] = worldToLatLng(x, b.minY, effCfg)
      const [latT, lngT] = worldToLatLng(x, b.maxY, effCfg)
      const ptB = map.latLngToContainerPoint([latB, lngB])
      const ptT = map.latLngToContainerPoint([latT, lngT])
      ctx.beginPath()
      ctx.moveTo(ptB.x, ptB.y)
      ctx.lineTo(ptT.x, ptT.y)
      ctx.stroke()
    }
    for (let ri = 0; ri <= 9; ri++) {
      const y = b.minY + ri * cellH
      const [latL, lngL] = worldToLatLng(b.minX, y, effCfg)
      const [latR, lngR] = worldToLatLng(b.maxX, y, effCfg)
      const ptL = map.latLngToContainerPoint([latL, lngL])
      const ptR = map.latLngToContainerPoint([latR, lngR])
      ctx.beginPath()
      ctx.moveTo(ptL.x, ptL.y)
      ctx.lineTo(ptR.x, ptR.y)
      ctx.stroke()
    }

    // Zone labels — A(bottom/minY row) to I(top/maxY row), 1..9 left to right
    for (let ci = 0; ci < 9; ci++) {
      for (let ri = 0; ri < 9; ri++) {
        const cx = b.minX + (ci + 0.5) * cellW
        const cy = b.minY + (ri + 0.5) * cellH
        const [lat, lng] = worldToLatLng(cx, cy, effCfg)
        const pt = map.latLngToContainerPoint([lat, lng])
        if (pt.x < -20 || pt.x > mapSize.x + 20 || pt.y < -20 || pt.y > mapSize.y + 20) continue
        const label = `${DD_ROWS[ri]}${DD_COLS[ci]}`
        ctx.fillText(label, pt.x, pt.y)
      }
    }
  }, [map, effCfg])

  useEffect(() => {
    const container = map.getContainer()
    const canvas = document.createElement('canvas')
    canvas.style.cssText = 'position:absolute;left:0;top:0;pointer-events:none;z-index:497'
    container.appendChild(canvas)
    canvasRef.current = canvas
    return () => {
      canvas.remove()
      canvasRef.current = null
    }
  }, [map])

  useEffect(() => {
    map.on('move zoom moveend zoomend viewreset resize', draw)
    draw()
    return () => {
      map.off('move zoom moveend zoomend viewreset resize', draw)
    }
  }, [map, draw])

  return null
}

// ── Fit-bounds bridge (must render inside MapContainer to access useMap) ───────
function FitBoundsController({ fitRef }: { fitRef: React.MutableRefObject<(() => void) | null> }) {
  const map = useMap()
  useEffect(() => {
    fitRef.current = () => map.fitBounds(IMAGE_BOUNDS, { animate: true })
  }, [map, fitRef])
  return null
}

// ── Filter Panel (persistent sidebar) ────────────────────────────────────────

const LIVE_TYPES = ['players', 'vehicles', 'bases'] as const

const CATEGORY_GROUPS: { id: string, labelKey: string }[] = [
  { id: 'locations', labelKey: 'liveMap.filterLocations' },
  { id: 'resources', labelKey: 'liveMap.filterResources' },
  { id: 'npcs', labelKey: 'liveMap.filterNPCs' },
  { id: 'vendors', labelKey: 'liveMap.filterVendors' },
  { id: 'trainers', labelKey: 'liveMap.filterTrainers' },
  { id: 'landsraad', labelKey: 'liveMap.filterLandsraad' },
  { id: 'pentashield_keys', labelKey: 'liveMap.filterKeys' },
  { id: 'vehicles', labelKey: 'liveMap.vehicles' },
  { id: 'static', labelKey: 'liveMap.filterStaticObjects' },
  { id: 'hazards', labelKey: 'liveMap.filterHazards' },
]

// FilterPanel is always-visible — no open/close state, rendered inline as a left sidebar.
function FilterPanel({
  filter, onToggle, onClear, spawns, mapKey, heatmapMode, onHeatmapToggle,
}: {
  filter: Record<string, boolean>
  onToggle: (key: string, currentVisual: boolean) => void
  onClear: () => void
  spawns: SpawnEntry[]
  mapKey: string
  heatmapMode: boolean
  onHeatmapToggle: () => void
}) {
  const { t } = useTranslation()
  const [search, setSearch] = useState('')
  const [expanded, setExpanded] = useState<Record<string, boolean>>({})

  // Build unique type list per category with counts
  const typesByCategory = useMemo(() => {
    const map: Record<string, Map<string, { label: string, count: number }>> = {}
    spawns.forEach((s) => {
      const cat = s.category
      if (!map[cat]) map[cat] = new Map()
      const key = filterKey(s.type)
      const label = TYPE_LABELS[key] ?? s.label ?? s.type.replace(/_/g, ' ')
      const existing = map[cat].get(key)
      map[cat].set(key, { label, count: (existing?.count ?? 0) + 1 })
    })
    return map
  }, [spawns])

  const LIVE_LABELS: Record<string, string> = {
    players: t('liveMap.players'),
    vehicles: t('liveMap.vehicles'),
    bases: t('liveMap.filterBases'),
  }

  type TypeRowProps = { typeKey: string, label: string, count: number, category: string }
  function TypeRow({ typeKey, label, count, category }: TypeRowProps) {
    const isOn = filter[typeKey] ?? false
    return (
      <label className="flex items-center gap-2 py-1.5 px-3 cursor-pointer hover:bg-surface-secondary rounded-[var(--radius)] select-none">
        <input
          type="checkbox"
          checked={isOn}
          onChange={() => onToggle(typeKey, isOn)}
          className="h-3.5 w-3.5 accent-accent shrink-0"
        />
        <SpriteIcon type={typeKey} size={18} />
        {!ICON_POS[typeKey] && (
          <span style={{ color: CAT_COLOR[category] }} className="shrink-0">●</span>
        )}
        <span className="flex-1 text-xs text-foreground truncate">{label}</span>
        <span className="text-xs text-muted tabular-nums shrink-0">{count.toLocaleString()}</span>
      </label>
    )
  }

  function CategorySection({ group }: { group: (typeof CATEGORY_GROUPS)[number] }) {
    const items = typesByCategory[group.id]
    if (!items?.size) return null
    const isExpanded = expanded[group.id] ?? false
    const allOn = [...items.keys()].every((k) => filter[k] ?? false)
    const anyOn = [...items.keys()].some((k) => filter[k] ?? false)
    const q = search.toLowerCase()
    const filteredItems = q
      ? [...items.entries()].filter(([k, v]) => v.label.toLowerCase().includes(q) || k.toLowerCase().includes(q))
      : [...items.entries()]

    if (q && filteredItems.length === 0) return null

    return (
      <div className="mb-1">
        <div className="flex items-center gap-1 px-2 py-1.5">
          <input
            type="checkbox"
            checked={allOn}
            ref={(el) => { if (el) el.indeterminate = !allOn && anyOn }}
            onChange={(e) => {
              const target = e.target.checked
              ;[...items.keys()].forEach((k) => onToggle(k, !target))
            }}
            className="h-3.5 w-3.5 accent-accent shrink-0"
          />
          <button
            type="button"
            className="flex-1 flex items-center gap-1.5 text-left"
            onClick={() => setExpanded((e) => ({ ...e, [group.id]: !e[group.id] }))}
          >
            <span style={{ color: CAT_COLOR[group.id] }} className="text-xs shrink-0">●</span>
            <span className="text-xs font-medium text-muted uppercase tracking-wide">{t(group.labelKey as never)}</span>
            <span className="text-xs text-muted/60 ml-1">
              {[...items.values()].reduce((s, v) => s + v.count, 0).toLocaleString()}
            </span>
            <Icon
              name={isExpanded || q ? 'chevron-down' : 'chevron-right'}
              className="size-3 text-muted ml-auto"
            />
          </button>
        </div>
        {(isExpanded || !!q) && (
          <div className="ml-1">
            {filteredItems.map(([key, { label, count }]) => (
              <TypeRow key={key} typeKey={key} label={label} count={count} category={group.id} />
            ))}
          </div>
        )}
      </div>
    )
  }

  return (
    <div className="flex flex-col w-60 shrink-0 min-h-0 overflow-hidden border-r border-border bg-background">
      {/* Search */}
      <div className="px-2 pt-2 pb-1 shrink-0">
        <SearchField
          aria-label={t('liveMap.filter')}
          value={search}
          onChange={setSearch}
        >
          <SearchField.Group>
            <SearchField.SearchIcon />
            <SearchField.Input placeholder={t('liveMap.filterSearch')} />
            <SearchField.ClearButton />
          </SearchField.Group>
        </SearchField>
      </div>
      <div className="px-2 pb-1 shrink-0 flex justify-end">
        <button
          type="button"
          onClick={onClear}
          className="text-xs text-muted hover:text-accent transition-colors"
        >
          {t('liveMap.clearFilters')}
        </button>
      </div>

      {/* Scrollable content */}
      <div className="flex-1 overflow-y-auto px-2 pb-2">
        {/* Live section */}
        {!search && (
          <Panel className="mb-2 mt-1">
            <SectionLabel>{t('liveMap.filterLive')}</SectionLabel>
            {LIVE_TYPES.map((id) => (
              <label key={id} className="flex items-center gap-2 py-1.5 cursor-pointer hover:bg-surface-secondary rounded-[var(--radius)] select-none px-1">
                <input
                  type="checkbox"
                  checked={filter[id] ?? false}
                  onChange={() => onToggle(id, filter[id] ?? false)}
                  className="h-3.5 w-3.5 accent-accent shrink-0"
                />
                <span style={{ color: CAT_COLOR[id] }} className="text-xs shrink-0">●</span>
                <span className="flex-1 text-xs text-foreground">{LIVE_LABELS[id]}</span>
              </label>
            ))}
          </Panel>
        )}

        {/* Density overlay toggle + legend — only for maps that have heatmap data */}
        {!search && HEATMAP_BOUNDS[mapKey] && (
          <Panel className="mb-2">
            <SectionLabel>{t('liveMap.filterDensity')}</SectionLabel>
            <label className="flex items-center gap-2 py-1.5 cursor-pointer hover:bg-surface-secondary rounded-[var(--radius)] select-none px-1">
              <input
                type="checkbox"
                checked={heatmapMode}
                onChange={onHeatmapToggle}
                className="h-3.5 w-3.5 accent-accent shrink-0"
              />
              <Icon name="layers" className="text-accent shrink-0" />
              <span className="flex-1 text-xs text-foreground">{t('liveMap.densityOverlay')}</span>
            </label>
            {heatmapMode && (() => {
              const active = (HEATMAP_TYPES[mapKey] ?? []).filter((type) => filter[heatmapFilterKey(type)] ?? false)
              if (!active.length) return (
                <p className="text-xs text-muted px-1 pb-1">{t('liveMap.densityNoneSelected')}</p>
              )
              return (
                <div className="px-1 pb-1 flex flex-col gap-0.5">
                  {active.map((type) => (
                    <div key={type} className="flex items-center gap-1.5">
                      <span className="w-3 h-3 rounded-sm shrink-0 opacity-80" style={{ background: HEATMAP_COLORS[type] ?? '#888' }} />
                      <span className="text-xs text-muted truncate">{TYPE_LABELS[type] ?? type.replace(/_/g, ' ')}</span>
                    </div>
                  ))}
                </div>
              )
            })()}
          </Panel>
        )}

        {/* Static category sections */}
        {CATEGORY_GROUPS.map((group) => (
          <CategorySection key={group.id} group={group} />
        ))}
      </div>
    </div>
  )
}

// ── Main component ────────────────────────────────────────────────────────────

const LIVE_FILTER_DEFAULTS: Record<string, boolean> = {
  players: true, vehicles: true, bases: true,
}
const FILTER_LS_KEY = 'dune_admin_livemap_filter'

function loadFilter(): Record<string, boolean> {
  try {
    const saved = JSON.parse(localStorage.getItem(FILTER_LS_KEY) ?? '{}') as Record<string, boolean>
    return { ...LIVE_FILTER_DEFAULTS, ...saved }
  }
  catch {
    return LIVE_FILTER_DEFAULTS
  }
}

function saveFilter(f: Record<string, boolean>) {
  try {
    localStorage.setItem(FILTER_LS_KEY, JSON.stringify(f))
  }
  catch { /* quota */ }
}

export default function LiveMapTab({ isActive = true }: { isActive?: boolean }) {
  const { t } = useTranslation()
  const [mapKey, setMapKey] = useState<string>('HaggaBasin')
  const [markers, setMarkers] = useState<MapMarker[]>([])
  const [loading, setLoading] = useState(false)
  const [unsupported, setUnsupported] = useState(false)
  const [updatedLabel, setUpdatedLabel] = useState<string>('')
  const [calibrating, setCalibrating] = useState(false)
  const [calibPoints, setCalibPoints] = useState<CalibPoint[]>([])
  const [calibOverride, setCalibOverride] = useState<Record<string, Bounds>>(() => loadCalib())

  const [spawns, setSpawns] = useState<SpawnEntry[]>([])
  const loadedSpawnKey = useRef<string>('')
  const isDragging = useRef(false)

  // filter persisted to localStorage — panel is always visible
  const [filter, setFilter] = useState<Record<string, boolean>>(loadFilter)
  const [selectedFlsId, setSelectedFlsId] = useState<string>('')
  const [dragConfirm, setDragConfirm] = useState<{
    flsId: string
    name: string
    x: number
    y: number
  } | null>(null)

  const [heatmapMode, setHeatmapMode] = useState(false)
  const fitBoundsRef = useRef<(() => void) | null>(null)
  const [teleportMode, setTeleportMode] = useState(false)
  const [teleportDest, setTeleportDest] = useState<{ x: number, y: number } | null>(null)
  const [teleportFlsId, setTeleportFlsId] = useState<string>('')
  const [allPlayers, setAllPlayers] = useState<Player[]>([])
  const [teleporting, setTeleporting] = useState(false)

  const baseCfg = MAPS.find((m) => m.key === mapKey) ?? MAPS[0]
  const effCfg: MapCfg = useMemo(
    () => ({ ...baseCfg, ...(calibOverride[mapKey] ?? {}) }),
    [baseCfg, calibOverride, mapKey],
  )

  const load = useCallback((key: string) => {
    if (isDragging.current) return
    const cfg = MAPS.find((m) => m.key === key)
    if (!cfg?.hasLiveData) {
      setMarkers([])
      setUnsupported(false)
      setUpdatedLabel(new Date().toLocaleTimeString())
      return
    }
    Promise.resolve()
      .then(() => {
        if (isDragging.current) return
        setLoading(true)
        setUnsupported(false)
      })
      .then(() => api.map.markers(key))
      .then((rows) => {
        if (isDragging.current) return
        setMarkers(rows)
        setUpdatedLabel(new Date().toLocaleTimeString())
      })
      .catch((e: unknown) => {
        if (isDragging.current) return
        if (e instanceof ApiError && e.status === 404) setUnsupported(true)
        else toast.danger(t('liveMap.failedToLoad', { message: e instanceof Error ? e.message : String(e) }))
        setMarkers([])
      })
      .finally(() => { if (!isDragging.current) setLoading(false) })
  }, [t])

  const loadCurrent = useCallback(() => load(mapKey), [load, mapKey])
  useEffect(() => {
    if (isActive) {
      const id = setTimeout(loadCurrent, 0)
      return () => clearTimeout(id)
    }
  }, [isActive, loadCurrent])
  const { countdown, refresh } = useAutoRefresh(loadCurrent, POLL_MS, isActive)

  useEffect(() => {
    const cfg = MAPS.find((m) => m.key === mapKey)
    if (!cfg?.spawnFile || loadedSpawnKey.current === mapKey) return
    loadedSpawnKey.current = mapKey
    fetch(mapUrl(`map-data/${cfg.spawnFile}-spawns.json`))
      .then((r) => r.json() as Promise<SpawnFile>)
      .then((d) => setSpawns(d.spawns))
      .catch(() => setSpawns([]))
  }, [mapKey])

  useEffect(() => {
    if (teleportMode && allPlayers.length === 0) {
      api.players.list().then(setAllPlayers).catch(() => {})
    }
  }, [teleportMode, allPlayers.length])

  const playerCount = markers.filter((m) => m.type === 'player').length
  const vehicleCount = markers.filter((m) => m.type === 'vehicle').length
  const orderedLive = useMemo(
    () => [...markers]
      .sort((a, b) => (a.type === 'player' ? 1 : 0) - (b.type === 'player' ? 1 : 0))
      .map((m) => {
        const isPlayer = m.type === 'player'
        const size = isPlayer ? 32 : 24
        const baseColor = CAT_COLOR[m.type] ?? CAT_COLOR.base
        const label = isPlayer ? (m.name?.[0]?.toUpperCase() ?? '?') : '🚗'
        const cursor = isPlayer ? 'grab' : 'default'
        const makeHtml = (color: string) =>
          `<div style="width:${size}px;height:${size}px;border-radius:50%;background:${color};border:2.5px solid #0b0b0b;box-shadow:0 0 0 1.5px ${color}40;display:flex;align-items:center;justify-content:center;font-size:9px;font-weight:700;color:#0b0b0b;line-height:1;cursor:${cursor}">${label}</div>`
        const iconOpts = { iconSize: [size, size] as L.PointTuple, iconAnchor: [size / 2, size / 2] as L.PointTuple, className: '' }
        return {
          ...m,
          center: worldToLatLng(m.x, m.y, effCfg) as L.LatLngTuple,
          isPlayer,
          size,
          icon: L.divIcon({ ...iconOpts, html: makeHtml(baseColor) }),
          selectedIcon: L.divIcon({ ...iconOpts, html: makeHtml('#f59e0b') }),
        }
      }),
    [markers, effCfg],
  )

  const handleMapClick = useCallback((lat: number, lng: number) => {
    if (calibrating) {
      const player = markers.find((m) => m.type === 'player')
      if (!player) {
        toast.danger(t('liveMap.calibNoPlayer'))
        return
      }
      setCalibPoints((prev) => {
        const next = [...prev, { wx: player.x, wy: player.y, fracX: lng / IMG_W, fracYup: lat / IMG_H }]
        const solved = solveBounds(next)
        if (solved) {
          setCalibOverride((c) => {
            const merged = { ...c, [mapKey]: solved }
            try {
              localStorage.setItem(CALIB_LS_KEY, JSON.stringify(merged))
            }
            catch { /* quota */ }
            return merged
          })
        }
        return next
      })
      return
    }
    if (teleportMode) {
      const { x, y } = latLngToWorld(lat, lng, effCfg)
      setTeleportDest({ x: Math.round(x), y: Math.round(y) })
    }
  }, [calibrating, teleportMode, markers, mapKey, effCfg, t])

  const clearCalib = useCallback(() => {
    setCalibPoints([])
    setCalibOverride((c) => {
      const merged = { ...c }
      delete merged[mapKey]
      try {
        localStorage.setItem(CALIB_LS_KEY, JSON.stringify(merged))
      }
      catch { /* quota */ }
      return merged
    })
  }, [mapKey])

  const solvedStr = useMemo(() => {
    const b = calibOverride[mapKey]
    return b
      ? `minX: ${Math.round(b.minX)}, maxX: ${Math.round(b.maxX)}, minY: ${Math.round(b.minY)}, maxY: ${Math.round(b.maxY)}, flipY: ${!!b.flipY}`
      : ''
  }, [calibOverride, mapKey])

  const doTeleport = useCallback(async () => {
    if (!teleportDest || !teleportFlsId) return
    setTeleporting(true)
    try {
      await api.players.teleportCoords(teleportFlsId, teleportDest.x, teleportDest.y, 5000)
      toast.success(t('liveMap.teleportSent'))
      setTeleportDest(null)
    }
    catch (e) {
      toast.danger(e instanceof Error ? e.message : String(e))
    }
    finally {
      setTeleporting(false)
    }
  }, [teleportDest, teleportFlsId, t])

  const toggleFilter = useCallback((key: string, currentVisual: boolean) => {
    setFilter((f) => {
      const next = { ...f, [key]: !currentVisual }
      saveFilter(next)
      return next
    })
  }, [])

  const clearFilters = useCallback(() => {
    setFilter((f) => {
      const next: Record<string, boolean> = {}
      Object.keys(f).forEach((k) => {
        next[k] = false
      })
      Object.assign(next, LIVE_FILTER_DEFAULTS)
      saveFilter(next)
      return next
    })
  }, [])

  const mapCursor = calibrating || teleportMode ? 'crosshair' : 'grab'
  const currentMap = MAPS.find((m) => m.key === mapKey) ?? MAPS[0]

  return (
    <div className="flex flex-col h-full gap-3 min-h-0">

      <PageHeader title={t('liveMap.title')} subtitle={t('liveMap.subtitle')}>
        <Button size="sm" variant="ghost" onPress={refresh} isDisabled={loading}>
          {loading
            ? <Spinner size="sm" color="current" />
            : (
                <>
                  {isActive && currentMap.hasLiveData && (
                    <span className="w-7 text-right tabular-nums text-muted/60 text-xs">
                      {countdown}
                      s
                    </span>
                  )}
                  <Icon name="refresh-cw" />
                </>
              )}
        </Button>
      </PageHeader>

      <div className="shrink-0 flex items-start gap-2 rounded-[var(--radius)] border border-border bg-surface px-3 py-2 text-xs">
        <Icon name="flask-conical" className="size-4 shrink-0 mt-0.5 text-accent" />
        <div>
          <span className="font-medium text-accent">{t('liveMap.betaTitle')}</span>
          {' '}
          <span className="text-muted">{t('liveMap.betaBody')}</span>
        </div>
      </div>

      {/* Toolbar — map dropdown + mode buttons */}
      <div className="flex items-center gap-2 shrink-0">
        {/* Map selector dropdown */}
        <Select
          aria-label={t('liveMap.title')}
          selectedKey={mapKey}
          onSelectionChange={(k) => {
            const key = String(k)
            loadedSpawnKey.current = ''
            setMapKey(key)
            setSpawns([])
            setTeleportDest(null)
            setCalibrating(false)
          }}
          className="w-44"
        >
          <Select.Trigger>
            <Icon name="map" className="size-3.5 text-muted shrink-0 mr-1" />
            <Select.Value />
            <Select.Indicator />
          </Select.Trigger>
          <Select.Popover>
            <ListBox>
              {MAPS.map((m) => (
                <ListBox.Item key={m.key} id={m.key} textValue={m.label}>
                  {m.label}
                  <ListBox.ItemIndicator />
                </ListBox.Item>
              ))}
            </ListBox>
          </Select.Popover>
        </Select>

        <div className="h-4 border-l border-border mx-0.5" />

        <Button size="sm" variant="outline" onPress={() => fitBoundsRef.current?.()}>
          <Icon name="home" />
        </Button>

        <Button
          size="sm"
          variant={teleportMode ? 'primary' : 'outline'}
          onPress={() => {
            setTeleportMode((v) => !v)
            setTeleportDest(null)
          }}
        >
          <Icon name="navigation" />
          {' '}
          {t('liveMap.teleportMode')}
        </Button>
        <Button size="sm" variant={calibrating ? 'primary' : 'outline'} onPress={() => setCalibrating((v) => !v)}>
          <Icon name="crosshair" />
          {' '}
          {t('liveMap.calibrate')}
        </Button>
        {calibrating && (
          <Button size="sm" variant="outline" onPress={clearCalib}>{t('liveMap.clear')}</Button>
        )}
      </div>

      {/* Stats bar */}
      <div className="flex flex-wrap gap-4 shrink-0 text-xs text-muted">
        {currentMap.hasLiveData && (
          <>
            <span>
              <span style={{ color: CAT_COLOR.player }}>●</span>
              {' '}
              {t('liveMap.players')}
              {': '}
              {playerCount}
            </span>
            <span>
              <span style={{ color: CAT_COLOR.vehicle }}>●</span>
              {' '}
              {t('liveMap.vehicles')}
              {': '}
              {vehicleCount}
            </span>
            <span>
              {t('liveMap.total')}
              {': '}
              {markers.length}
            </span>
          </>
        )}
        {spawns.length > 0 && <span>{t('liveMap.spawnsLoaded', { count: spawns.length })}</span>}
        {updatedLabel !== '' && <span className="ml-auto">{t('liveMap.updated', { time: updatedLabel })}</span>}
      </div>

      {/* Teleport panel */}
      {teleportMode && (
        <div className="shrink-0 rounded-[var(--radius)] border border-accent/40 bg-surface px-3 py-2 text-xs flex flex-wrap items-center gap-3">
          <div className="text-accent font-medium">
            <Icon name="navigation" className="size-3 inline mr-1" />
            {teleportDest
              ? t('liveMap.spawnTooltipCoords', { x: teleportDest.x, y: teleportDest.y })
              : t('liveMap.teleportModeActive')}
          </div>
          {teleportDest && (
            <>
              <Select
                aria-label={t('liveMap.teleportPlayer')}
                placeholder={t('liveMap.teleportSelectPlayer')}
                selectedKey={teleportFlsId || null}
                onSelectionChange={(k) => setTeleportFlsId(k ? String(k) : '')}
                className="w-56"
              >
                <Select.Trigger>
                  <Select.Value />
                  <Select.Indicator />
                </Select.Trigger>
                <Select.Popover>
                  <ListBox>
                    {allPlayers.map((p) => (
                      <ListBox.Item key={p.fls_id} id={p.fls_id} textValue={p.name}>
                        {p.name}
                        <ListBox.ItemIndicator />
                      </ListBox.Item>
                    ))}
                  </ListBox>
                </Select.Popover>
              </Select>
              <Button size="sm" isDisabled={!teleportFlsId || teleporting} onPress={doTeleport}>
                {teleporting ? <Spinner size="sm" color="current" /> : t('liveMap.teleportHere')}
              </Button>
              <Button size="sm" variant="ghost" onPress={() => setTeleportDest(null)}>✕</Button>
            </>
          )}
        </div>
      )}

      {/* Calibration hint */}
      {calibrating && (
        <div className="shrink-0 rounded-[var(--radius)] border border-border bg-surface px-3 py-2 text-xs">
          <div className="text-accent">{t('liveMap.calibActive')}</div>
          <div className="text-muted">{t('liveMap.calibPoints', { n: calibPoints.length })}</div>
          {solvedStr && <div className="mt-1 font-mono text-foreground break-all">{solvedStr}</div>}
        </div>
      )}

      {/* Filter panel (left) + map (right) — filter is always visible */}
      <div className="flex flex-1 min-h-0 gap-0 overflow-hidden">
        <FilterPanel
          filter={filter}
          onToggle={toggleFilter}
          onClear={clearFilters}
          spawns={spawns}
          mapKey={mapKey}
          heatmapMode={heatmapMode}
          onHeatmapToggle={() => setHeatmapMode((v) => !v)}
        />
        {unsupported
          ? <div className="flex-1 py-8 text-center text-sm text-muted">{t('liveMap.unsupported')}</div>
          : (
              <div className="relative flex-1 min-h-0 overflow-hidden rounded-[var(--radius)] border border-border">
                <MapContainer
                  crs={CRS.Simple}
                  bounds={IMAGE_BOUNDS}
                  minZoom={-3}
                  maxZoom={4}
                  zoomSnap={0.25}
                  attributionControl={false}
                  style={{ height: '100%', width: '100%', background: 'var(--color-surface)', cursor: mapCursor }}
                >
                  <InvalidateOnActive active={isActive} />
                  <MapClickCapture active={calibrating || teleportMode} onPick={handleMapClick} />
                  {effCfg.tileId
                    ? <MapTileLayer key={mapKey} tileId={effCfg.tileId} />
                    : effCfg.image && (
                      <ImageOverlay
                        key={mapKey}
                        url={mapUrl(`map-data/${effCfg.image}`)}
                        bounds={IMAGE_BOUNDS}
                      />
                    )}

                  {/* Terrain depth overlay — hillshade+AO blended with multiply */}
                  {effCfg.depthFile && (
                    <ImageOverlay
                      key={`depth-${mapKey}`}
                      url={mapUrl(`map-data/${effCfg.depthFile}`)}
                      bounds={IMAGE_BOUNDS}
                      className="leaflet-depth-overlay"
                    />
                  )}

                  <FitBoundsController fitRef={fitBoundsRef} />

                  {/* Deep Desert zone grid overlay */}
                  {mapKey === 'DeepDesert' && (
                    <ZoneGridLayer effCfg={effCfg} />
                  )}

                  {/* Density heatmap overlay — drawn below spawn icons */}
                  {heatmapMode && (
                    <HeatmapCanvasLayer
                      mapKey={mapKey}
                      effCfg={effCfg}
                      filter={filter}
                    />
                  )}

                  {/* All static spawns rendered on a single canvas — O(1) DOM */}
                  <SpawnCanvasLayer
                    spawns={spawns}
                    effCfg={effCfg}
                    filter={filter}
                    heatmapMode={heatmapMode}
                  />

                  {/* Live entity markers — draggable for direct teleport */}
                  {(filter.players || filter.vehicles) && orderedLive
                    .filter((m) => m.type === 'player' ? filter.players : filter.vehicles)
                    .map((m) => {
                      const { center, isPlayer, size, icon, selectedIcon } = m
                      const isSelected = m.fls_id === selectedFlsId
                      return (
                        <Marker
                          key={`${m.type}-${m.id}`}
                          position={center}
                          icon={isSelected ? selectedIcon : icon}
                          draggable={isPlayer}
                          eventHandlers={{
                            click: () => {
                              if (m.fls_id) {
                                setSelectedFlsId((prev) => prev === m.fls_id ? '' : m.fls_id!)
                                setTeleportFlsId(m.fls_id!)
                              }
                            },
                            dragstart: () => { isDragging.current = true },
                            dragend: (e) => {
                              isDragging.current = false
                              if (!m.fls_id) return
                              const marker = e.target as L.Marker
                              const { lat, lng } = marker.getLatLng()
                              marker.setLatLng(center)
                              const { x, y } = latLngToWorld(lat, lng, effCfg)
                              setDragConfirm({
                                flsId: m.fls_id!,
                                name: m.name || m.fls_id!,
                                x: Math.round(x),
                                y: Math.round(y),
                              })
                            },
                          }}
                        >
                          <Tooltip direction="top" offset={[0, -(size / 2)]}>
                            <div className="font-medium">{m.name || `${m.type} ${m.id}`}</div>
                            <div className="text-xs opacity-70">
                              {m.type}
                              {m.online_status ? ` · ${m.online_status}` : ''}
                            </div>
                            <div className="text-xs font-mono">
                              {Math.round(m.x)}
                              {', '}
                              {Math.round(m.y)}
                            </div>
                            {isPlayer && <div className="text-xs text-accent mt-0.5">Drag to teleport</div>}
                          </Tooltip>
                        </Marker>
                      )
                    })}

                  {/* Teleport destination */}
                  {teleportDest && (
                    <CircleMarker
                      center={worldToLatLng(teleportDest.x, teleportDest.y, effCfg)}
                      radius={10}
                      pathOptions={{ color: '#ffffff', weight: 2, fillColor: '#f59e0b', fillOpacity: 0.85 }}
                    >
                      <Tooltip permanent>
                        <span className="text-xs">
                          {teleportDest.x}
                          ,
                          {' '}
                          {teleportDest.y}
                        </span>
                      </Tooltip>
                    </CircleMarker>
                  )}

                  {calibrating && calibPoints.map((p, i) => (
                    <CircleMarker
                      key={`calib-${i}`}
                      center={[p.fracYup * IMG_H, p.fracX * IMG_W]}
                      radius={5}
                      pathOptions={{ color: '#ffffff', weight: 2, fillColor: '#ff2bd6', fillOpacity: 0.9 }}
                    >
                      <Tooltip>{`calib ${i + 1}`}</Tooltip>
                    </CircleMarker>
                  ))}
                </MapContainer>
              </div>
            )}

      </div>

      <ConfirmDialog
        open={dragConfirm !== null}
        title={t('liveMap.dragTeleportTitle', { name: dragConfirm?.name ?? '' })}
        description={t('liveMap.dragTeleportDesc', { x: dragConfirm?.x ?? 0, y: dragConfirm?.y ?? 0 })}
        confirmLabel={t('liveMap.teleportHere')}
        onConfirm={async () => {
          if (!dragConfirm) return
          try {
            await api.players.teleportCoords(dragConfirm.flsId, dragConfirm.x, dragConfirm.y, 5000)
            toast.success(t('liveMap.teleportSent'))
          }
          catch (err) {
            toast.danger(err instanceof Error ? err.message : String(err))
          }
          setDragConfirm(null)
        }}
        onCancel={() => setDragConfirm(null)}
      />
    </div>
  )
}
