package marketbot

import (
	"database/sql"
	"errors"
	"os"
	"path/filepath"
	"testing"
	"time"

	"github.com/jackc/pgx/v5"
)

// newTestExchange returns an Exchange with a temporary file-based SQLite cache
// suitable for unit tests that exercise epoch learning (which writes to e.cache).
func newTestExchange(t *testing.T) *Exchange {
	t.Helper()
	dbPath := filepath.Join(t.TempDir(), "test-cache.db")
	cache, err := sql.Open("sqlite", dbPath)
	if err != nil {
		t.Fatalf("open test sqlite: %v", err)
	}
	t.Cleanup(func() { _ = cache.Close() })
	if _, err := cache.Exec(`CREATE TABLE IF NOT EXISTS metadata (
		key   TEXT    PRIMARY KEY,
		value INTEGER NOT NULL
	)`); err != nil {
		t.Fatalf("init metadata table: %v", err)
	}
	return &Exchange{cache: cache}
}

func TestEnsureCachePathCreatesParentDirectories(t *testing.T) {
	root := t.TempDir()
	cachePath := filepath.Join(root, "nested", "cache", "market-bot.db")

	resolved, err := ensureCachePath(cachePath)
	if err != nil {
		t.Fatalf("ensureCachePath returned error: %v", err)
	}
	if resolved != cachePath {
		t.Fatalf("ensureCachePath returned %q, want %q", resolved, cachePath)
	}
	if _, err := os.Stat(filepath.Dir(cachePath)); err != nil {
		t.Fatalf("expected cache directory to exist: %v", err)
	}
}

func TestEnsureCachePathRejectsEmptyPath(t *testing.T) {
	if _, err := ensureCachePath("   "); err == nil {
		t.Fatalf("ensureCachePath should reject empty path")
	}
}

func TestConfigValuesIsDisabled(t *testing.T) {
	snap := configValues{
		DisabledItems: []string{"item.sword", "item.shield"},
	}
	if !snap.isDisabled("item.sword") {
		t.Error("item.sword should be disabled")
	}
	if !snap.isDisabled("item.shield") {
		t.Error("item.shield should be disabled")
	}
	if snap.isDisabled("item.axe") {
		t.Error("item.axe should NOT be disabled")
	}
	if snap.isDisabled("") {
		t.Error("empty string should NOT be disabled")
	}

	// Case-insensitive match.
	if !snap.isDisabled("ITEM.SWORD") {
		t.Error("isDisabled should be case-insensitive")
	}
}

func TestConfigValuesIsDisabledEmpty(t *testing.T) {
	snap := configValues{}
	if snap.isDisabled("anything") {
		t.Error("empty DisabledItems list should never block any item")
	}
}

// TestEpochSentinelCutoffExcludesSentinel verifies that the sentinel
// expiration_time value (999_999_999) is excluded from epoch detection.
// The SQL query uses WHERE expiration_time < epochSentinelCutoff, so the
// sentinel itself must equal epochSentinelCutoff to be excluded by the strict
// less-than comparison.
func TestEpochSentinelCutoffExcludesSentinel(t *testing.T) {
	t.Parallel()

	// The sentinel must equal the cutoff so that "< epochSentinelCutoff" in
	// the SQL excludes it. If the cutoff were > 999_999_999, sentinel listings
	// would pass the filter and corrupt the epoch calculation.
	if epochSentinelCutoff != 999_999_999 {
		t.Errorf("epochSentinelCutoff = %d, want 999_999_999 "+
			"(SQL uses < epochSentinelCutoff to exclude sentinel listings)",
			epochSentinelCutoff)
	}
}

// TestApplyLearnedEpoch_SkipsOnError verifies that applyLearnedEpoch does not
// modify the Exchange when fetchRef returns an error.
func TestApplyLearnedEpoch_SkipsOnError(t *testing.T) {
	t.Parallel()

	ex := &Exchange{gameEpochUnix: 12345}
	applyLearnedEpoch(ex, func() (int64, error) {
		return 0, errors.New("no rows")
	})
	if ex.gameEpochUnix != 12345 {
		t.Errorf("gameEpochUnix changed on error: got %d, want 12345", ex.gameEpochUnix)
	}
}

// TestApplyLearnedEpoch_SkipsOnZeroRef verifies that applyLearnedEpoch does not
// modify the Exchange when fetchRef returns 0 (no matching row).
func TestApplyLearnedEpoch_SkipsOnZeroRef(t *testing.T) {
	t.Parallel()

	ex := &Exchange{gameEpochUnix: 99}
	applyLearnedEpoch(ex, func() (int64, error) {
		return 0, nil
	})
	if ex.gameEpochUnix != 99 {
		t.Errorf("gameEpochUnix changed on zero ref: got %d, want 99", ex.gameEpochUnix)
	}
}

// TestLearnGameEpoch_FallsBackToPlayerListingsOnBootstrap verifies the two-tier
// epoch detection strategy:
//  1. First tries bot's own non-sentinel listings (fast, accurate path).
//  2. Falls back to player listings when no qualifying bot listings exist.
//
// This covers the bootstrap case: on a fresh install or after cache clearing,
// the only bot listings are sentinel listings (expiration_time = 999_999_999).
// The first tier returns no rows, so the second tier (player listings) must be
// tried so the bot can bootstrap the epoch from real player expirations.
func TestLearnGameEpoch_FallsBackToPlayerListingsOnBootstrap(t *testing.T) {
	t.Parallel()

	// On bootstrap: bot has only sentinel listings — tier 1 returns no rows.
	// Player listing provides a real expiration_time.
	const playerExpiry = int64(1_800_000)

	ex := newTestExchange(t)
	ex.gameEpochUnix = 0
	calls := 0
	applyLearnedEpochTwoTier(ex,
		func() (int64, error) {
			calls++
			return 0, pgx.ErrNoRows // no non-sentinel bot listings
		},
		func() (int64, error) {
			calls++
			return playerExpiry, nil // player listing found
		},
	)

	if calls != 2 {
		t.Errorf("expected 2 fetch calls (tier1 miss + tier2 hit), got %d", calls)
	}
	if ex.gameEpochUnix == 0 {
		t.Error("gameEpochUnix should have been updated from player listing fallback")
	}
}

// TestLearnGameEpoch_UsesBotListingsWhenAvailable verifies that when the bot has
// non-sentinel listings, tier 1 succeeds and tier 2 is never called.
func TestLearnGameEpoch_UsesBotListingsWhenAvailable(t *testing.T) {
	t.Parallel()

	const botExpiry = int64(1_900_000)

	ex := newTestExchange(t)
	ex.gameEpochUnix = 0
	tier2Called := false
	applyLearnedEpochTwoTier(ex,
		func() (int64, error) {
			return botExpiry, nil // bot has a real listing
		},
		func() (int64, error) {
			tier2Called = true
			return 0, pgx.ErrNoRows
		},
	)

	if tier2Called {
		t.Error("tier 2 (player listing fallback) should not be called when tier 1 succeeds")
	}
	if ex.gameEpochUnix == 0 {
		t.Error("gameEpochUnix should have been updated from bot listing")
	}
}

// TestLearnGameEpoch_SkipsTier2WhenEpochAlreadyKnown verifies that once an
// epoch is established, a subsequent Tier 1 miss (e.g. after cleanup deletes
// all bot listings) does NOT invoke the Tier 2 player-listing fallback.
//
// The Tier 2 fallback assumes player listings last orderExpirySecs (24 h).
// Real player listings last ~30 days, so Tier 2 would compute gameNow ≈ 29
// days too high, making expireAndPurgeOrders delete every valid bot listing.
func TestLearnGameEpoch_SkipsTier2WhenEpochAlreadyKnown(t *testing.T) {
	t.Parallel()

	const knownEpoch = int64(999_000)
	ex := newTestExchange(t)
	ex.gameEpochUnix = knownEpoch

	tier2Called := false
	applyLearnedEpochTwoTier(ex,
		func() (int64, error) { return 0, pgx.ErrNoRows }, // Tier 1: no bot listings (post-cleanup)
		func() (int64, error) {
			tier2Called = true
			return 3_000_000, nil // player listing with ~30-day duration: would corrupt epoch
		},
	)

	if tier2Called {
		t.Error("Tier 2 must not fire when a valid epoch is already known (prevents post-cleanup corruption)")
	}
	if ex.gameEpochUnix != knownEpoch {
		t.Errorf("epoch changed from %d to %d; Tier 2 must not overwrite a known epoch",
			knownEpoch, ex.gameEpochUnix)
	}
}

// TestLearnGameEpoch_AllowsTier2OnBootstrapWithZeroEpoch verifies that Tier 2
// is still consulted on a genuine fresh install where no epoch has been
// established yet (gameEpochUnix == 0).
func TestLearnGameEpoch_AllowsTier2OnBootstrapWithZeroEpoch(t *testing.T) {
	t.Parallel()

	ex := newTestExchange(t)
	ex.gameEpochUnix = 0 // no epoch yet (fresh install)

	tier2Called := false
	applyLearnedEpochTwoTier(ex,
		func() (int64, error) { return 0, pgx.ErrNoRows }, // Tier 1: no bot listings
		func() (int64, error) {
			tier2Called = true
			return 100_000, nil // player listing
		},
	)

	if !tier2Called {
		t.Error("Tier 2 should be consulted when epoch is 0 (bootstrap scenario)")
	}
	if ex.gameEpochUnix == 0 {
		t.Error("epoch should have been updated from player listing on bootstrap")
	}
}

// TestLearnGameEpoch_BothTiersMissDoesNotUpdate verifies that when both tiers
// return no rows, the epoch is left unchanged (no spurious zero write).
func TestLearnGameEpoch_BothTiersMissDoesNotUpdate(t *testing.T) {
	t.Parallel()

	ex := newTestExchange(t)
	ex.gameEpochUnix = 42
	applyLearnedEpochTwoTier(ex,
		func() (int64, error) { return 0, pgx.ErrNoRows },
		func() (int64, error) { return 0, pgx.ErrNoRows },
	)

	if ex.gameEpochUnix != 42 {
		t.Errorf("gameEpochUnix changed unexpectedly: got %d, want 42", ex.gameEpochUnix)
	}
}

// TestApplyLearnedEpoch_SkipsRefAtSentinel verifies that applyLearnedEpoch does
// not update the epoch when the reference expiration_time equals epochSentinelCutoff.
// This is the sentinel value used for "expiration unknown" orders (e.g. leftover
// standalone bot orders with is_npc_order=FALSE and expiration_time=999_999_999).
// Without this guard, Tier 2 picking up such an order makes gameNow near-sentinel,
// causing buyPlayerListings to filter out ALL valid player listings.
func TestApplyLearnedEpoch_SkipsRefAtSentinel(t *testing.T) {
	t.Parallel()

	ex := &Exchange{gameEpochUnix: 42}
	applyLearnedEpoch(ex, func() (int64, error) {
		return epochSentinelCutoff, nil // sentinel ref from leftover bot order
	})
	if ex.gameEpochUnix != 42 {
		t.Errorf("epoch updated from sentinel ref: got %d, want 42", ex.gameEpochUnix)
	}
}

// TestApplyLearnedEpoch_SkipsRefAboveSentinel verifies that applyLearnedEpoch
// rejects any ref > epochSentinelCutoff (defensive against non-standard sentinel values).
func TestApplyLearnedEpoch_SkipsRefAboveSentinel(t *testing.T) {
	t.Parallel()

	ex := &Exchange{gameEpochUnix: 99}
	applyLearnedEpoch(ex, func() (int64, error) {
		return epochSentinelCutoff + 1, nil
	})
	if ex.gameEpochUnix != 99 {
		t.Errorf("epoch updated from above-sentinel ref: got %d, want 99", ex.gameEpochUnix)
	}
}

// TestApplyLearnedEpoch_AcceptsValidRef verifies that a normal (well below sentinel)
// ref still updates the epoch correctly after the sentinel guard is added.
func TestApplyLearnedEpoch_AcceptsValidRef(t *testing.T) {
	t.Parallel()

	const validRef = int64(2_000_000) // well below sentinel
	ex := newTestExchange(t)
	ex.gameEpochUnix = 0
	applyLearnedEpoch(ex, func() (int64, error) {
		return validRef, nil
	})
	if ex.gameEpochUnix == 0 {
		t.Error("epoch should have been updated from valid ref")
	}
}

// TestLearnGameEpoch_Tier2SentinelRefDoesNotCorruptEpoch is the end-to-end
// regression test for the "bot not buying listings" bug. When Tier 2 returns a
// sentinel-value expiration_time (from a leftover standalone bot order), the
// epoch must NOT be set — otherwise gameNow becomes near-sentinel and
// buyPlayerListings filters out every valid player listing.
func TestLearnGameEpoch_Tier2SentinelRefDoesNotCorruptEpoch(t *testing.T) {
	t.Parallel()

	ex := newTestExchange(t)
	ex.gameEpochUnix = 0 // fresh install, no cached epoch

	applyLearnedEpochTwoTier(ex,
		func() (int64, error) { return 0, pgx.ErrNoRows },         // Tier 1: no bot listings
		func() (int64, error) { return epochSentinelCutoff, nil }, // Tier 2: sentinel leftover
	)

	if ex.gameEpochUnix != 0 {
		t.Errorf("epoch was set from sentinel Tier 2 ref: got %d, want 0 (must stay unknown)", ex.gameEpochUnix)
	}
}

// TestClearSentinelEpoch_ClearsWhenNearSentinel verifies that clearSentinelEpoch
// resets gameEpochUnix to 0 when the cached epoch would produce a near-sentinel
// gameNow. This auto-heals a corrupted cache from a previous run where Tier 2
// picked up a sentinel-value player order and wrote the bad epoch to SQLite.
func TestClearSentinelEpoch_ClearsWhenNearSentinel(t *testing.T) {
	t.Parallel()

	// An epoch that makes gameNow() == epochSentinelCutoff - orderExpirySecs.
	// gameNow() = time.Now().Unix() - gameEpochUnix
	// → gameEpochUnix = time.Now().Unix() - (epochSentinelCutoff - orderExpirySecs)
	badEpoch := time.Now().Unix() - (epochSentinelCutoff - orderExpirySecs)
	ex := &Exchange{gameEpochUnix: badEpoch}
	cleared := clearSentinelEpoch(ex)
	if !cleared {
		t.Error("clearSentinelEpoch should return true for near-sentinel epoch")
	}
	if ex.gameEpochUnix != 0 {
		t.Errorf("gameEpochUnix should be 0 after clearing, got %d", ex.gameEpochUnix)
	}
}

// TestClearSentinelEpoch_KeepsValidEpoch verifies that clearSentinelEpoch does
// not disturb a healthy epoch that produces a reasonable gameNow.
func TestClearSentinelEpoch_KeepsValidEpoch(t *testing.T) {
	t.Parallel()

	// A valid epoch: gameNow() ≈ 1_000_000 (well below sentinel).
	validEpoch := time.Now().Unix() - 1_000_000
	ex := &Exchange{gameEpochUnix: validEpoch}
	cleared := clearSentinelEpoch(ex)
	if cleared {
		t.Error("clearSentinelEpoch should return false for a valid epoch")
	}
	if ex.gameEpochUnix != validEpoch {
		t.Errorf("valid epoch should be preserved: got %d, want %d", ex.gameEpochUnix, validEpoch)
	}
}

// TestClearSentinelEpoch_NoopOnZeroEpoch verifies clearSentinelEpoch is a no-op
// when epoch is 0 (unknown — nothing to clear).
func TestClearSentinelEpoch_NoopOnZeroEpoch(t *testing.T) {
	t.Parallel()

	ex := &Exchange{gameEpochUnix: 0}
	cleared := clearSentinelEpoch(ex)
	if cleared {
		t.Error("clearSentinelEpoch should return false when epoch is already 0")
	}
}

// TestCategoryFor_* exercises categoryFor in isolation (no DB required).
// These tests verify the three-tier precedence:
//  1. Live player-derived cache (authoritative — matched mask prevents snapshot conflicts)
//  2. UniqueSchematicsMask (for schematics with a known unique section)
//  3. CategoryMask (known segment codes only; returns ok=false when mask=0)
//
// They also verify the ok=false skip signal prevents (0,0) pollution.

func newTestExchangeWithCategories(t *testing.T, cats map[string]categoryEntry) *Exchange {
	t.Helper()
	e := &Exchange{
		categories: cats,
	}
	// Build a minimal segment index so CategoryMask can resolve known categories.
	catalog := make([]CatalogItem, 0)
	for tmpl := range cats {
		catalog = append(catalog, CatalogItem{TemplateID: tmpl})
	}
	e.segIdx = buildSegmentIndex(catalog)
	return e
}

// TestBuyExpiryCutoff verifies that the buy query's game-time expiry filter only
// activates when the epoch is known. When gameNow <= 0 the cutoff is 0, which
// triggers the SQL ($2 = 0 OR ...) short-circuit — no player orders are touched.
//
// CRITICAL: this filter is a SELECT guard only. The bot must NEVER delete or
// expire player (is_npc_order=FALSE) orders. Players collect their items and
// Solari at the exchange access point. The game server's dune_exchange_expire_orders
// proc owns the lifecycle of player orders — we must not interfere.
func TestBuyExpiryCutoff(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name       string
		gameNow    int64
		wantCutoff int64
	}{
		{"zero skips filter (epoch unknown)", 0, 0},
		{"negative skips filter", -1, 0},
		{"positive passes through as cutoff", 1_800_000, 1_800_000},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := buyExpiryCutoff(tt.gameNow); got != tt.wantCutoff {
				t.Errorf("buyExpiryCutoff(%d) = %d, want %d", tt.gameNow, got, tt.wantCutoff)
			}
		})
	}
}

// --- Player game epoch tests (issue #142) ---

// TestApplyLearnedPlayerEpoch_SkipsOnError verifies that applyLearnedPlayerEpoch
// does not modify playerGameEpochUnix when fetchRef returns an error.
func TestApplyLearnedPlayerEpoch_SkipsOnError(t *testing.T) {
	t.Parallel()

	ex := &Exchange{playerGameEpochUnix: 12345}
	applyLearnedPlayerEpoch(ex, func() (int64, error) {
		return 0, errors.New("no rows")
	})
	if ex.playerGameEpochUnix != 12345 {
		t.Errorf("playerGameEpochUnix changed on error: got %d, want 12345", ex.playerGameEpochUnix)
	}
}

// TestApplyLearnedPlayerEpoch_SkipsOnZeroRef verifies that applyLearnedPlayerEpoch
// does not modify playerGameEpochUnix when fetchRef returns 0.
func TestApplyLearnedPlayerEpoch_SkipsOnZeroRef(t *testing.T) {
	t.Parallel()

	ex := &Exchange{playerGameEpochUnix: 99}
	applyLearnedPlayerEpoch(ex, func() (int64, error) { return 0, nil })
	if ex.playerGameEpochUnix != 99 {
		t.Errorf("playerGameEpochUnix changed on zero ref: got %d, want 99", ex.playerGameEpochUnix)
	}
}

// TestApplyLearnedPlayerEpoch_SkipsSentinel verifies that a ref equal to
// epochSentinelCutoff does not update playerGameEpochUnix.
func TestApplyLearnedPlayerEpoch_SkipsSentinel(t *testing.T) {
	t.Parallel()

	ex := &Exchange{playerGameEpochUnix: 42}
	applyLearnedPlayerEpoch(ex, func() (int64, error) { return epochSentinelCutoff, nil })
	if ex.playerGameEpochUnix != 42 {
		t.Errorf("epoch updated from sentinel ref: got %d, want 42", ex.playerGameEpochUnix)
	}
}

// TestApplyLearnedPlayerEpoch_SkipsAboveSentinel verifies that a ref above
// epochSentinelCutoff does not update playerGameEpochUnix.
func TestApplyLearnedPlayerEpoch_SkipsAboveSentinel(t *testing.T) {
	t.Parallel()

	ex := &Exchange{playerGameEpochUnix: 42}
	applyLearnedPlayerEpoch(ex, func() (int64, error) { return epochSentinelCutoff + 1, nil })
	if ex.playerGameEpochUnix != 42 {
		t.Errorf("epoch updated from above-sentinel ref: got %d, want 42", ex.playerGameEpochUnix)
	}
}

// TestApplyLearnedPlayerEpoch_SetsEpochFromPlayerListing verifies that a valid
// player listing expiry sets playerGameEpochUnix so that playerGameNow() returns
// approximately expiry - orderExpirySecs (i.e. the player market game time).
// This is the core fix for issue #142: the player clock must be tracked
// separately from the NPC clock so the buy-side cutoff uses the right timebase.
func TestApplyLearnedPlayerEpoch_SetsEpochFromPlayerListing(t *testing.T) {
	t.Parallel()

	const playerExpiry = int64(1_363_606) // example value from issue #142 report
	ex := newTestExchange(t)

	applyLearnedPlayerEpoch(ex, func() (int64, error) { return playerExpiry, nil })

	if ex.playerGameEpochUnix == 0 {
		t.Fatal("playerGameEpochUnix should be set after learning from a player listing")
	}
	wantPlayerNow := playerExpiry - orderExpirySecs
	gotPlayerNow := time.Now().Unix() - ex.playerGameEpochUnix
	if diff := gotPlayerNow - wantPlayerNow; diff < -5 || diff > 5 {
		t.Errorf("playerGameNow() ≈ %d, want ≈ %d (delta %d seconds)", gotPlayerNow, wantPlayerNow, diff)
	}
}

// TestApplyLearnedPlayerEpoch_UpdatesOnChange verifies that playerGameEpochUnix
// is updated when a new, different expiration_time is observed.
func TestApplyLearnedPlayerEpoch_UpdatesOnChange(t *testing.T) {
	t.Parallel()

	ex := newTestExchange(t)
	ex.playerGameEpochUnix = 100 // stale/initial value

	const newExpiry = int64(1_500_000)
	applyLearnedPlayerEpoch(ex, func() (int64, error) { return newExpiry, nil })

	wantEpoch := time.Now().Unix() - (newExpiry - orderExpirySecs)
	if diff := ex.playerGameEpochUnix - wantEpoch; diff < -5 || diff > 5 {
		t.Errorf("playerGameEpochUnix = %d, want ≈ %d", ex.playerGameEpochUnix, wantEpoch)
	}
}

// TestPlayerGameNow_ZeroWhenEpochUnknown verifies that playerGameNow returns 0
// when playerGameEpochUnix has not been set.
func TestPlayerGameNow_ZeroWhenEpochUnknown(t *testing.T) {
	t.Parallel()

	ex := &Exchange{}
	if got := ex.playerGameNow(); got != 0 {
		t.Errorf("playerGameNow() = %d, want 0 when playerGameEpochUnix is 0", got)
	}
}

// TestPlayerGameNow_ReturnsCurrentPlayerTime verifies that playerGameNow returns
// approximately the expected player game time based on playerGameEpochUnix.
func TestPlayerGameNow_ReturnsCurrentPlayerTime(t *testing.T) {
	t.Parallel()

	const wantGameNow = int64(1_277_206) // inferred player game time from issue #142
	ex := &Exchange{
		playerGameEpochUnix: time.Now().Unix() - wantGameNow,
	}
	got := ex.playerGameNow()
	if diff := got - wantGameNow; diff < -2 || diff > 2 {
		t.Errorf("playerGameNow() = %d, want ≈ %d (delta %d)", got, wantGameNow, diff)
	}
}

// TestBuyTickUsesPlayerClockNotNPCClock is the regression test for issue #142.
// It verifies that the player clock and NPC clock are treated as independent
// values, so a large gap between the two (as observed in production) does not
// cause the NPC-derived cutoff to filter out valid player listings.
//
// Key invariant: buyExpiryCutoff(playerGameNow) must not be confused with
// buyExpiryCutoff(npcGameNow). When the player market game clock origin is
// ~17 days behind the NPC clock, passing npcGameNow as the cutoff makes
// player listing expiry times (~1.36M) appear already expired relative to the
// NPC-derived cutoff (~2.75M).
func TestBuyTickUsesPlayerClockNotNPCClock(t *testing.T) {
	t.Parallel()

	// Reproduce the exact values from the issue #142 report.
	const npcGameNow = int64(2_752_244)    // bot's NPC clock
	const playerGameNow = int64(1_277_206) // player market clock
	const playerExpiry = int64(1_363_606)  // fresh 1-day player listing (1277206 + 86400)

	// With the NPC cutoff the listing is incorrectly filtered (1363606 > 2752244 = false).
	if buyExpiryCutoff(npcGameNow) <= playerExpiry {
		t.Errorf("test precondition: expected npcGameNow cutoff %d to exceed playerExpiry %d",
			npcGameNow, playerExpiry)
	}

	// With the player cutoff the listing is correctly included (1363606 > 1277206 = true).
	if buyExpiryCutoff(playerGameNow) >= playerExpiry {
		t.Errorf("player cutoff %d should be less than playerExpiry %d (listing is valid)",
			playerGameNow, playerExpiry)
	}
}

func TestCategoryFor_LiveCacheTakesPrecedenceOverComputedMask(t *testing.T) {
	t.Parallel()

	// Cache says this template uses mask 0x05010000 (misc/refinedresources).
	// The CatalogItem has a different category that would compute a different mask.
	// categoryFor must return the cached values, not the computed ones.
	e := newTestExchangeWithCategories(t, map[string]categoryEntry{
		"item.resource.spice": {mask: 0x05010000, depth: 2},
	})

	item := CatalogItem{
		TemplateID: "item.resource.spice",
		Category:   "items/weapons/pistol", // would compute 0x01020000 if used
	}
	mask, depth, ok := e.categoryFor(item)
	if !ok {
		t.Fatal("categoryFor returned ok=false for a cached template")
	}
	if mask != 0x05010000 {
		t.Errorf("mask = 0x%08X, want 0x05010000 (live cache must win)", uint32(mask))
	}
	if depth != 2 {
		t.Errorf("depth = %d, want 2", depth)
	}
}

func TestCategoryFor_LiveCacheZeroMaskFallsThrough(t *testing.T) {
	t.Parallel()

	// A cache entry with mask=0 must not be used — fall through to computed path.
	e := newTestExchangeWithCategories(t, map[string]categoryEntry{
		"item.weapon.pistol": {mask: 0, depth: 0},
	})
	// Build a proper segment index for a known category.
	catalog := []CatalogItem{{Category: "items/weapons/pistol"}}
	e.segIdx = buildSegmentIndex(catalog)

	item := CatalogItem{
		TemplateID: "item.weapon.pistol",
		Category:   "items/weapons/pistol",
	}
	mask, _, ok := e.categoryFor(item)
	if !ok {
		t.Fatal("categoryFor returned ok=false for a known category even though cache mask=0")
	}
	if mask == 0 {
		t.Error("expected a non-zero mask from CategoryMask fallback")
	}
}

func TestCategoryFor_SchematicUsesUniqueSchematics(t *testing.T) {
	t.Parallel()

	e := &Exchange{
		categories: map[string]categoryEntry{},
	}
	e.segIdx = buildSegmentIndex(nil)

	// A schematic with a known UNIQUE SCHEMATICS section (e.g. weapons/pistol).
	item := CatalogItem{
		TemplateID:  "bp.weapon.pistol",
		Category:    "items/weapons/pistol",
		IsSchematic: true,
	}
	_, _, ok := UniqueSchematicsMask(item.Category)
	if !ok {
		t.Skip("test requires items/weapons/pistol to have a unique-schematics section")
	}

	mask, depth, ok := e.categoryFor(item)
	if !ok {
		t.Fatal("categoryFor returned ok=false for schematic with unique-schematics section")
	}
	if mask == 0 {
		t.Error("expected non-zero unique-schematics mask")
	}
	if depth == 0 {
		t.Error("expected non-zero depth for unique-schematics")
	}
}

func TestCategoryFor_EmptyCategoryNotInCacheReturnsNotOK(t *testing.T) {
	t.Parallel()

	// No cache entry, no category — must return ok=false, never (0,0) with ok=true.
	e := &Exchange{
		categories: map[string]categoryEntry{},
	}
	e.segIdx = buildSegmentIndex(nil)

	item := CatalogItem{
		TemplateID: "item.unknown.thing",
		Category:   "",
	}
	mask, depth, ok := e.categoryFor(item)
	if ok {
		t.Errorf("expected ok=false for item with no category and no cache entry, got mask=0x%08X depth=%d", uint32(mask), depth)
	}
	if mask != 0 || depth != 0 {
		t.Errorf("expected (0,0) sentinel with ok=false, got (0x%08X, %d)", uint32(mask), depth)
	}
}

func TestCategoryFor_KnownCategoryNoCacheReturnsMask(t *testing.T) {
	t.Parallel()

	// No cache entry, but a fully known category — CategoryMask succeeds.
	catalog := []CatalogItem{{Category: "items/misc/refinedresources"}}
	e := &Exchange{
		categories: map[string]categoryEntry{},
		segIdx:     buildSegmentIndex(catalog),
	}

	item := CatalogItem{
		TemplateID: "item.misc.spice",
		Category:   "items/misc/refinedresources",
	}
	mask, _, ok := e.categoryFor(item)
	if !ok {
		t.Fatal("categoryFor returned ok=false for a fully known category")
	}
	if mask == 0 {
		t.Errorf("CategoryMask should return non-zero for items/misc/refinedresources")
	}
}

func TestCategoryFor_UnknownCategorySegmentReturnsNotOK(t *testing.T) {
	t.Parallel()

	// A category whose segments are not in knownCodes and not in the segment index.
	// CategoryMask must return 0 (after fix #3 removes the alphabetical fallback),
	// and categoryFor must propagate ok=false.
	e := &Exchange{
		categories: map[string]categoryEntry{},
		segIdx:     buildSegmentIndex(nil),
	}

	item := CatalogItem{
		TemplateID: "item.future.thing",
		Category:   "items/totallynewtype/unknownsub",
	}
	_, _, ok := e.categoryFor(item)
	if ok {
		t.Error("categoryFor should return ok=false for a category with unknown segments (no alphabetical fallback)")
	}
}

func TestDetectExchangeID(t *testing.T) {
	errNoRows := pgx.ErrNoRows
	panicFn := func() (int64, error) { panic("should not be called") }

	tests := []struct {
		name            string
		fromAccessPoint func() (int64, error)
		fromOrders      func() (int64, error)
		fromTable       func() (int64, error)
		autoCreate      func() (int64, error)
		wantID          int64
		wantErr         bool
	}{
		{
			// Authoritative: the access point is what the game actually uses,
			// so it wins even when player orders point elsewhere (the bug:
			// stale orders on the phantom Global exchange).
			name:            "found via access point (authoritative)",
			fromAccessPoint: func() (int64, error) { return 2, nil },
			fromOrders:      panicFn,
			fromTable:       panicFn,
			autoCreate:      panicFn,
			wantID:          2,
		},
		{
			name:            "falls back to player orders when no access point",
			fromAccessPoint: func() (int64, error) { return 0, errNoRows },
			fromOrders:      func() (int64, error) { return 7, nil },
			fromTable:       panicFn,
			autoCreate:      panicFn,
			wantID:          7,
		},
		{
			name:            "falls back to dune_exchanges table",
			fromAccessPoint: func() (int64, error) { return 0, errNoRows },
			fromOrders:      func() (int64, error) { return 0, errNoRows },
			fromTable:       func() (int64, error) { return 3, nil },
			autoCreate:      panicFn,
			wantID:          3,
		},
		{
			name:            "auto-creates via upsert when everything empty",
			fromAccessPoint: func() (int64, error) { return 0, errNoRows },
			fromOrders:      func() (int64, error) { return 0, errNoRows },
			fromTable:       func() (int64, error) { return 0, errNoRows },
			autoCreate:      func() (int64, error) { return 1, nil },
			wantID:          1,
		},
		{
			name:            "all tiers fail → error",
			fromAccessPoint: func() (int64, error) { return 0, errNoRows },
			fromOrders:      func() (int64, error) { return 0, errNoRows },
			fromTable:       func() (int64, error) { return 0, errNoRows },
			autoCreate:      func() (int64, error) { return 0, errNoRows },
			wantErr:         true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			id, err := detectExchangeID(tt.fromAccessPoint, tt.fromOrders, tt.fromTable, tt.autoCreate)
			if tt.wantErr {
				if err == nil {
					t.Error("expected error, got nil")
				}
				return
			}
			if err != nil {
				t.Fatalf("unexpected error: %v", err)
			}
			if id != tt.wantID {
				t.Errorf("got id=%d want %d", id, tt.wantID)
			}
		})
	}
}

// TestSellerPaymentExpiry_AlwaysSentinel is the regression test for the
// "payment purged before collection" bug.
//
// When the bot buys a player's listing it hand-rolls the trade: it inserts a
// synthetic "Take Solari" entry (dune_exchange_orders, is_npc_order=FALSE) with
// expiration_time = sellerPaymentExpiry(...), then deletes the player's real
// listing + item in the same transaction. The live game server runs
// dune_exchange_expire_orders every ~5 min; if that synthetic entry's
// expiration_time ≤ the game's real current time it is purged before the player
// collects → item gone, no Solaris, nothing in Completed ("eaten").
//
// Fix: sellerPaymentExpiry must always return epochSentinelCutoff (999_999_999)
// so the entry is never automatically expired by the game server.
// The orderExpiry argument (gameNow + 24 h) must be ignored entirely — an
// uncollected payment should not disappear 24 h later.
//
// Bonus: sentinel expiry also removes these FALSE-flag rows from Tier-2 epoch
// detection (SQL uses WHERE expiration_time < epochSentinelCutoff) so they can
// no longer corrupt the bot's gameNow reconstruction.
func TestSellerPaymentExpiry_AlwaysSentinel(t *testing.T) {
	t.Parallel()

	cases := []struct {
		name        string
		orderExpiry int64
	}{
		{"normal order expiry (gameNow + 24h)", int64(1_800_000 + 86_400)},
		{"zero — epoch unknown on first boot", 0},
		{"sentinel — bot placed with far-future expiry", epochSentinelCutoff},
		{"very large value", 999_999_998},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()
			got := sellerPaymentExpiry(tc.orderExpiry)
			if got != epochSentinelCutoff {
				t.Errorf("sellerPaymentExpiry(%d) = %d, want epochSentinelCutoff (%d): "+
					"seller payment must never auto-expire before the player collects",
					tc.orderExpiry, got, epochSentinelCutoff)
			}
		})
	}
}

// TestSellerPaymentItemPrice_IsPerUnit is a regression test for the
// double-multiplication overpayment bug.
//
// dune_exchange_orders.item_price is a PER-UNIT price. When a seller claims their
// payout ("Take Solari"), the game computes: payout = item_price × stack_size
// (from dune_exchange_fulfilled_orders). Storing totalCost (unitPrice×stackSize)
// as item_price caused the game to pay unitPrice×stackSize×stackSize.
//
// Example: 200 darts listed at 80 each → bot debited 16,000 (correct) →
// seller received 16,000×200 = 3,200,000 instead of 16,000.
func TestSellerPaymentItemPrice_IsPerUnit(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name      string
		unitPrice int64
		stackSize int64
	}{
		{"single item", 80, 1},
		{"200-dart stack at 80 each (the observed overpay case)", 80, 200},
		{"high-value item small stack", 50_000, 5},
		{"zero price edge case", 0, 10},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()
			got := sellerPaymentItemPrice(tt.unitPrice)
			if got != tt.unitPrice {
				t.Errorf("sellerPaymentItemPrice(%d) = %d, want %d (per-unit, not total)",
					tt.unitPrice, got, tt.unitPrice)
			}
			// Verify the buggy value differs (for non-unit, non-zero stacks) to
			// confirm the fix actually changes something. When unitPrice==0 the
			// buggy and correct values are both 0, so the check is meaningless.
			if tt.stackSize > 1 && tt.unitPrice > 0 && got == tt.unitPrice*tt.stackSize {
				t.Errorf("returned totalCost=%d — double-multiplication bug still present",
					tt.unitPrice*tt.stackSize)
			}
		})
	}
}

func TestDetectAccessPointID(t *testing.T) {
	errNoRows := pgx.ErrNoRows

	tests := []struct {
		name             string
		fromAccessPoints func() (int64, error)
		fromOrders       func() (int64, error)
		want             int64
	}{
		{
			// Authoritative table wins, even if stale orders reference a
			// different (wrong) access point.
			name:             "from access points table",
			fromAccessPoints: func() (int64, error) { return 2, nil },
			fromOrders:       func() (int64, error) { panic("should not be called") },
			want:             2,
		},
		{
			name:             "falls back to existing orders",
			fromAccessPoints: func() (int64, error) { return 0, errNoRows },
			fromOrders:       func() (int64, error) { return 5, nil },
			want:             5,
		},
		{
			name:             "defaults to 1 when nothing found",
			fromAccessPoints: func() (int64, error) { return 0, errNoRows },
			fromOrders:       func() (int64, error) { return 0, errNoRows },
			want:             1,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := detectAccessPointID(tt.fromAccessPoints, tt.fromOrders); got != tt.want {
				t.Errorf("got %d want %d", got, tt.want)
			}
		})
	}
}
