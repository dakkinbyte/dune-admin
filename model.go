package main

import (
	"sort"
	"strings"
)

// dbItemTemplates is the merged, sorted list of item templates.
var dbItemTemplates []string

// ── domain types ─────────────────────────────────────────────────────────────

type playerInfo struct {
	ID           int64  `json:"id"`
	AccountID    int64  `json:"account_id"`
	ControllerID int64  `json:"controller_id"`
	FLSID        string `json:"fls_id"`
	Name         string `json:"name"`
	Class        string `json:"class"`
	Map          string `json:"map"`
	FactionID    int16  `json:"faction_id"`
	OnlineStatus string `json:"online_status"`
}

type journeyNode struct {
	NodeID           string `json:"node_id"`
	IsComplete       bool   `json:"is_complete"`
	IsRevealed       bool   `json:"is_revealed"`
	HasPendingReward bool   `json:"has_pending_reward"`
}

type itemInfo struct {
	ID            int64  `json:"id"`
	TemplateID    string `json:"template_id"`
	Name          string `json:"name"`
	StackSize     int64  `json:"stack_size"`
	Quality       int64  `json:"quality"`
	Durability    string `json:"durability"`
	MaxDurability string `json:"max_durability"`
}

type currencyRow struct {
	PlayerID   int64 `json:"player_id"`
	CurrencyID int16 `json:"currency_id"`
	Balance    int64 `json:"balance"`
}

type factionRep struct {
	ActorID     int64  `json:"actor_id"`
	FactionID   int16  `json:"faction_id"`
	FactionName string `json:"faction_name"`
	Reputation  int32  `json:"reputation"`
	Scrips      int64  `json:"scrips"`
}

type specTrack struct {
	PlayerID  int64   `json:"player_id"`
	TrackType string  `json:"track_type"`
	XP        int32   `json:"xp"`
	Level     float32 `json:"level"`
}

type itemRule struct {
	Name     string  `json:"name"`
	StackMax int64   `json:"stack_max"`
	Volume   float64 `json:"volume"`
	Tier     int     `json:"tier"`
	Rarity   string  `json:"rarity"`
}

type itemDataFile struct {
	DefaultStackMax int64               `json:"default_stack_max"`
	DefaultVolume   float64             `json:"default_volume"`
	Names           map[string]string   `json:"names"`
	Items           map[string]itemRule `json:"items"`
}

type blueprintRow struct {
	ID         int64  `json:"id"`
	OwnerName  string `json:"owner_name"`
	ItemID     int64  `json:"item_id"`
	Pieces     int64  `json:"pieces"`
	Placeables int64  `json:"placeables"`
	Name       string `json:"name"`
}

type baseRow struct {
	ID         int64  `json:"id"`
	Name       string `json:"name"`
	Pieces     int64  `json:"pieces"`
	Placeables int64  `json:"placeables"`
}

// ── message types (used by db.go cmd* functions) ──────────────────────────────

type msgConnect struct{ err error }
type msgPlayers struct {
	rows []playerInfo
	err  error
}
type msgInventory struct {
	rows []itemInfo
	err  error
}
type msgCurrency struct {
	rows []currencyRow
	err  error
}
type msgFactions struct {
	rows            []factionRep
	scripCurrencyID int16
	err             error
}
type msgSpecs struct {
	rows []specTrack
	err  error
}
type msgSQL struct {
	result string
	err    error
}
type msgMutate struct {
	ok  string
	err error
}
type msgJourney struct {
	rows []journeyNode
	err  error
}
type msgBlueprintList struct {
	rows []blueprintRow
	err  error
}
type msgBaseList struct {
	rows []baseRow
	err  error
}
type msgBlueprintExport struct {
	path string
	err  error
}
type msgItemTemplates struct {
	templates []string
}

type vehicleRow struct {
	ID                int64   `json:"id"`
	Class             string  `json:"class"`
	Map               string  `json:"map"`
	ChassisDurability float64 `json:"chassis_durability"`
	VehicleName       string  `json:"vehicle_name"`
	IsRecovered       bool    `json:"is_recovered"`
	IsBackup          bool    `json:"is_backup"`
}

type cheatEntry struct {
	FLSID         string `json:"fls_id"`
	CheatType     string `json:"cheat_type"`
	EventTime     string `json:"event_time"`
	CharacterName string `json:"character_name"`
}

type gameEvent struct {
	ActorID      int64   `json:"actor_id"`
	UniverseTime string  `json:"universe_time"`
	Map          string  `json:"map"`
	EventType    int32   `json:"event_type"`
	X            float64 `json:"x"`
	Y            float64 `json:"y"`
	Z            float64 `json:"z"`
	CustomData   string  `json:"custom_data"`
}

type dungeonRecord struct {
	DungeonID    string `json:"dungeon_id"`
	Difficulty   string `json:"difficulty"`
	DurationMs   int64  `json:"duration_ms"`
	PlayersNum   int    `json:"players_num"`
	CompletionID int64  `json:"completion_id"`
}

type teleportLocation struct {
	Name string  `json:"name"`
	X    float64 `json:"x"`
	Y    float64 `json:"y"`
	Z    float64 `json:"z"`
}

type msgVehicles struct {
	rows []vehicleRow
	err  error
}
type msgCheatLog struct {
	rows []cheatEntry
	err  error
}
type msgEvents struct {
	rows []gameEvent
	err  error
}
type msgDungeons struct {
	rows []dungeonRecord
	err  error
}
type msgPartitions struct {
	rows []teleportLocation
	err  error
}

type msgKeystones struct {
	ids []int16
	err error
}

type msgTags struct {
	rows []string
	err  error
}


// ── item template merge (called after connect) ────────────────────────────────

func mergeItemTemplates(dbTemplates []string) {
	seen := make(map[string]string)
	for _, t := range dbTemplates {
		seen[strings.ToLower(t)] = t
	}
	for k := range itemData.Names {
		if _, ok := seen[k]; !ok {
			seen[k] = k
		}
	}
	if itemData.Items != nil {
		for k := range itemData.Items {
			if _, ok := seen[k]; !ok {
				seen[k] = k
			}
		}
	}
	merged := make([]string, 0, len(seen))
	for _, v := range seen {
		merged = append(merged, v)
	}
	sort.Strings(merged)
	dbItemTemplates = merged
}
