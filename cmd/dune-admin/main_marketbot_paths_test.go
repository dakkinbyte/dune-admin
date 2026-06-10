package main

import (
	"os"
	"path/filepath"
	"testing"
)

func TestResolveEmbeddedMarketBotPaths(t *testing.T) {
	t.Parallel()

	t.Run("uses explicit config values", func(t *testing.T) {
		t.Parallel()
		cfg := appConfig{
			MarketBotCacheDB:  "/tmp/custom-cache.db",
			MarketBotItemData: "/tmp/custom-item-data.json",
			MarketBotState:    "/tmp/custom-state.json",
		}
		cacheDB, itemDataForBot, statePath := resolveEmbeddedMarketBotPaths(cfg, "/fallback.json")
		if cacheDB != "/tmp/custom-cache.db" {
			t.Fatalf("expected explicit cache db path, got %q", cacheDB)
		}
		if itemDataForBot != "/tmp/custom-item-data.json" {
			t.Fatalf("expected explicit item-data path, got %q", itemDataForBot)
		}
		if statePath != "/tmp/custom-state.json" {
			t.Fatalf("expected explicit state path, got %q", statePath)
		}
	})

	t.Run("falls back to provided item-data path", func(t *testing.T) {
		t.Parallel()
		cfg := appConfig{}
		cacheDB, itemDataForBot, statePath := resolveEmbeddedMarketBotPaths(cfg, "/fallback.json")
		wantCache := filepath.Join(configDir(), "market-bot-cache.db")
		if cacheDB != wantCache {
			t.Fatalf("expected default cache path %q, got %q", wantCache, cacheDB)
		}
		if itemDataForBot != "/fallback.json" {
			t.Fatalf("expected fallback item-data path, got %q", itemDataForBot)
		}
		wantState := filepath.Join(configDir(), "market-bot-state.json")
		if statePath != wantState {
			t.Fatalf("expected default state path %q, got %q", wantState, statePath)
		}
	})

	t.Run("marketBotEnabled defaults to true when nil", func(t *testing.T) {
		t.Parallel()
		cfg := appConfig{} // MarketBotEnabled is nil
		if !marketBotEnabled(cfg) {
			t.Error("marketBotEnabled should default to true when field is nil")
		}
	})

	t.Run("marketBotEnabled respects explicit false", func(t *testing.T) {
		t.Parallel()
		f := false
		cfg := appConfig{MarketBotEnabled: &f}
		if marketBotEnabled(cfg) {
			t.Error("marketBotEnabled should return false when explicitly set to false")
		}
	})
}

func TestItemDataPathResolvable(t *testing.T) {
	t.Parallel()
	dir := t.TempDir()
	file := filepath.Join(dir, "item-data.json")
	if err := os.WriteFile(file, []byte(`{"items":{}}`), 0o644); err != nil {
		t.Fatal(err)
	}
	tests := []struct {
		name string
		path string
		want bool
	}{
		{"empty", "", false},
		{"existing file", file, true},
		{"directory containing item-data.json", dir, true},
		{"directory without item-data.json", t.TempDir(), false},
		{"nonexistent path", filepath.Join(dir, "nope.json"), false},
		{"bogus value like the #136 report", "optional", false},
	}
	for _, tt := range tests {
		tt := tt
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()
			if got := itemDataPathResolvable(tt.path); got != tt.want {
				t.Fatalf("itemDataPathResolvable(%q) = %v, want %v", tt.path, got, tt.want)
			}
		})
	}
}

// #136: a stale/typo'd market_bot_item_data (e.g. "optional") must not crash bot
// startup — usableItemDataPath falls back to the standard search locations.
// Not parallel: mutates the itemDataPath global that resolveItemDataPath reads.
func TestUsableItemDataPath(t *testing.T) {
	dir := t.TempDir()
	good := filepath.Join(dir, "item-data.json")
	if err := os.WriteFile(good, []byte(`{"items":{}}`), 0o644); err != nil {
		t.Fatal(err)
	}
	orig := itemDataPath
	itemDataPath = good // makes resolveItemDataPath() return good
	t.Cleanup(func() { itemDataPath = orig })

	if got := usableItemDataPath(good); got != good {
		t.Fatalf("usable configured path: got %q, want %q (used as-is)", got, good)
	}
	if got := usableItemDataPath("optional"); got != good {
		t.Fatalf("bogus configured path: got %q, want fallback %q", got, good)
	}
	if got := usableItemDataPath(""); got != good {
		t.Fatalf("empty path: got %q, want fallback %q", got, good)
	}
}
