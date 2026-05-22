# Bases Export — Design Spec

**Date:** 2026-05-21  
**Status:** Approved

## Problem

The admin tool can manage blueprint solidos (player-saved building plans) but has no visibility into actual placed bases in the world. Admins cannot list what bases exist, who they belong to, or snapshot them as reusable blueprints.

## Goal

Add two backend endpoints and a UI tab that let admins list all live bases and export any base as a solido-compatible JSON file, importable via the existing `/api/v1/blueprints/import` endpoint.

---

## Data Model

### Relevant tables

| Table | Role |
|---|---|
| `buildings` | One row per base group (`id`) |
| `building_instances` | Structural pieces; `building_id` FK to `buildings`, `owner_entity_id` links to totem |
| `actor_fgl_entities` | Maps `entity_id → actor_id` (totem actor) |
| `actors` | Actor records; totem actor holds the base name via `permission_actor` |
| `permission_actor` | `actor_id, actor_name` — player-assigned base name lives here on the totem |
| `placeables` | Functional buildings (refineries, fabricators, lights, pentashields); `id = actor_id`, `owner_entity_id` matches building instances |
| `actors.transform` | Composite type `(location(x,y,z), rotation(qx,qy,qz,qw))`; used for placeable world positions |

### Name join path

```
building_instances.owner_entity_id
  → actor_fgl_entities.entity_id → actor_fgl_entities.actor_id  (totem actor)
  → permission_actor.actor_id    → permission_actor.actor_name   (base name)
```

---

## Backend

### New endpoints

#### `GET /api/v1/bases`

Returns all bases. No parameters.

Response: `[]baseRow`

```go
type baseRow struct {
    ID         int64  `json:"id"`
    Name       string `json:"name"`       // from permission_actor via totem
    Pieces     int64  `json:"pieces"`     // building_instances count
    Placeables int64  `json:"placeables"` // placeables count
}
```

Query joins `buildings → building_instances → actor_fgl_entities → actors (totem class) → permission_actor`. Groups by `buildings.id, actor_name`.

#### `GET /api/v1/bases/{id}/export`

Exports the base as a `blueprintFile` JSON — identical format to `/api/v1/blueprints/{id}/export`, importable via the existing import endpoint.

Response: `blueprintFile` (existing type: `instances`, `placeables`, `pentashields`).

### New file: `handlers_bases.go`

Contains `handleListBases`, `handleExportBase`, and transform helpers.

#### Export algorithm

1. **Fetch instances** — query `building_instances WHERE building_id = $1`; scan transform as `[]float32` (7 elements: X Y Z QX QY QZ QW).
2. **Compute centroid** — average X, Y, Z across all instances.
3. **Convert instances** — for each piece:
   - Position: subtract centroid
   - Rotation: `yaw_deg = atan2(2*(qw*qz + qx*qy), 1 - 2*(qy²+qz²)) * 180/π`
   - Emit `blueprintInstance{BuildingType, X, Y, Z, Rotation}`
4. **Get owner_entity_id** — from any instance row (all share the same value).
5. **Fetch placeables** — join `placeables p JOIN actors a ON a.id = p.id WHERE p.owner_entity_id = $1`; scan `building_type` and `(a.transform).location::text`, `(a.transform).rotation::text`; parse the PostgreSQL composite text format `(x,y,z)` / `(qx,qy,qz,qw)`.
6. **Convert placeables** — for each:
   - Position: subtract centroid
   - Rotation: quaternion → Euler degrees (roll, pitch, yaw)
   - Emit `blueprintPlaceable{BuildingType, X, Y, Z, RX, RY, RZ}`
7. **Pentashields** — detect `building_type` containing `PentashieldSurface`; check `actors.properties` JSONB for scale values; fall back to `[0, 0, 0]` if absent. Emit `blueprintPentashield{PlaceableID: index, Scale: [3]int}`.

#### Transform math

```
// Quaternion → yaw (degrees), for building instances
yaw = atan2(2*(qw*qz + qx*qy), 1 - 2*(qy²+qz²)) * (180/π)

// Quaternion → Euler (degrees), for placeables
roll  (RX) = atan2(2*(qw*qx + qy*qz), 1 - 2*(qx²+qy²)) * (180/π)
pitch (RY) = asin(clamp(2*(qw*qy - qz*qx), -1, 1))      * (180/π)
yaw   (RZ) = atan2(2*(qw*qz + qx*qy), 1 - 2*(qy²+qz²)) * (180/π)
```

### `db.go` addition

Add `cmdListBases() Msg` following the same `cmd*` pattern as `cmdListBlueprints`. Returns `msgBaseList{rows []baseRow, err error}`.

### `server.go` additions

```go
mux.HandleFunc("GET /api/v1/bases", handleListBases)
mux.HandleFunc("GET /api/v1/bases/{id}/export", handleExportBase)
```

---

## Frontend

### `web/src/api/client.ts`

Add under `api.bases`:

```ts
bases: {
  list: () => get<BaseRow[]>('/bases'),
  exportUrl: (id: number) => `${backendUrl()}/api/v1/bases/${id}/export`,
}
```

Add `BaseRow` type:

```ts
export interface BaseRow {
  id: number
  name: string
  pieces: number
  placeables: number
}
```

### `web/src/tabs/BasesTab.tsx`

New file. Mirrors `BlueprintsTab` structure:

- Header with title, description, Refresh button
- Spinner while loading
- Sticky-header table: columns `ID | Name | Pieces | Placeables | Actions`
- Export action: `<a href={api.bases.exportUrl(bp.id)} download={...}><Button>Export</Button></a>`
- No import modal — imports go through the Blueprints tab
- Empty state row when no bases

### `web/src/App.tsx`

- Import `BasesTab`
- Add `<Tabs.Tab id="bases">Bases<Tabs.Indicator /></Tabs.Tab>` alongside Blueprints (same `isSignedIn` gate)
- Add `<Tabs.Panel id="bases" className="flex-1 overflow-hidden flex flex-col p-4"><BasesTab /></Tabs.Panel>`

---

## Out of Scope

- Filtering bases by owner/player
- Pentashield scale recovery when not in `actors.properties` (falls back to `[0,0,0]`)
- Base deletion or modification
