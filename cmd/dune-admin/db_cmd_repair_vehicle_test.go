package main

import (
	"errors"
	"testing"

	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"
)

// durText builds a valid pgtype.Text holding a numeric durability string.
func durText(s string) pgtype.Text {
	return pgtype.Text{String: s, Valid: true}
}

func TestValidateRepairVehicleInput(t *testing.T) {
	originalDB := globalDB
	t.Cleanup(func() { globalDB = originalDB })

	globalDB = nil
	if err := validateRepairVehicleInput(42); err == nil || err.Error() != "not connected" {
		t.Fatalf("expected not connected error, got %v", err)
	}

	globalDB = &pgxpool.Pool{}
	if err := validateRepairVehicleInput(0); err == nil || err.Error() != "player ID required" {
		t.Fatalf("expected player ID required error, got %v", err)
	}
	if err := validateRepairVehicleInput(42); err != nil {
		t.Fatalf("expected valid input, got %v", err)
	}
}

func TestVehicleModuleRepairTarget(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name    string
		module  vehicleModule
		wantTgt float64
		wantOK  bool
	}{
		{
			name:    "in-row MaxDurability is the source of truth (regression: was halved by catalog)",
			module:  vehicleModule{maxDurability: durText("12000"), currentDurability: durText("6000"), decayedDurability: durText("6000")},
			wantTgt: 12000,
			wantOK:  true,
		},
		{
			name:   "no in-row MaxDurability is skipped, never guessed from catalog",
			module: vehicleModule{maxDurability: pgtype.Text{}, currentDurability: durText("6000")},
			wantOK: false,
		},
		{
			name:   "unparseable MaxDurability is skipped",
			module: vehicleModule{maxDurability: durText("oops")},
			wantOK: false,
		},
		{
			name:   "zero MaxDurability is skipped",
			module: vehicleModule{maxDurability: durText("0")},
			wantOK: false,
		},
		{
			name:    "never lowers an existing higher value",
			module:  vehicleModule{maxDurability: durText("100"), currentDurability: durText("80"), decayedDurability: durText("150")},
			wantTgt: 150,
			wantOK:  true,
		},
	}

	for _, tt := range tests {
		tt := tt
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()
			target, ok := vehicleModuleRepairTarget(tt.module)
			if ok != tt.wantOK {
				t.Fatalf("expected ok=%v, got ok=%v (target=%v)", tt.wantOK, ok, target)
			}
			if ok && target != tt.wantTgt {
				t.Fatalf("expected target=%v, got %v", tt.wantTgt, target)
			}
		})
	}
}

func TestVehicleModuleAtTarget(t *testing.T) {
	t.Parallel()

	full := vehicleModule{currentDurability: durText("12000"), decayedDurability: durText("12000")}
	if !vehicleModuleAtTarget(full, 12000) {
		t.Fatalf("expected full module to be at target")
	}

	damaged := vehicleModule{currentDurability: durText("6000"), decayedDurability: durText("6000")}
	if vehicleModuleAtTarget(damaged, 12000) {
		t.Fatalf("expected damaged module to not be at target")
	}
}

func TestRunVehicleModuleRepairs(t *testing.T) {
	t.Parallel()

	modules := []vehicleModule{
		{id: 1, maxDurability: durText("12000"), currentDurability: durText("6000"), decayedDurability: durText("6000")}, // repair → 12000
		{id: 2, maxDurability: pgtype.Text{}, currentDurability: durText("6000")},                                        // skip (no in-row max)
		{id: 3, maxDurability: durText("9000"), currentDurability: durText("9000"), decayedDurability: durText("9000")},  // full → no-op
		{id: 4, maxDurability: durText("12000"), currentDurability: durText("0"), decayedDurability: durText("12000")},   // repair → 12000
	}

	var repairedIDs []int64
	summary := runVehicleModuleRepairs(modules, func(module vehicleModule, target float64) error {
		if target != 12000 {
			t.Fatalf("expected target 12000, got %v for module %d", target, module.id)
		}
		repairedIDs = append(repairedIDs, module.id)
		return nil
	})
	if summary.err != nil {
		t.Fatalf("unexpected error: %v", summary.err)
	}
	if summary.total != 4 || summary.repaired != 2 || summary.skipped != 1 {
		t.Fatalf("unexpected summary: %+v", summary)
	}
	if len(repairedIDs) != 2 || repairedIDs[0] != 1 || repairedIDs[1] != 4 {
		t.Fatalf("unexpected repaired IDs: %v", repairedIDs)
	}
}

func TestRunVehicleModuleRepairs_StopsOnError(t *testing.T) {
	t.Parallel()

	modules := []vehicleModule{
		{id: 10, maxDurability: durText("125"), currentDurability: durText("0"), decayedDurability: durText("0")},
		{id: 11, maxDurability: durText("125"), currentDurability: durText("0"), decayedDurability: durText("0")},
		{id: 12, maxDurability: pgtype.Text{}},
	}

	failErr := errors.New("boom")
	summary := runVehicleModuleRepairs(modules, func(module vehicleModule, _ float64) error {
		if module.id == 11 {
			return failErr
		}
		return nil
	})
	if summary.err == nil {
		t.Fatalf("expected repair error")
	}
	if summary.err.Error() != "repair module 11: boom" {
		t.Fatalf("unexpected error: %v", summary.err)
	}
	if summary.total != 3 || summary.repaired != 1 || summary.skipped != 0 {
		t.Fatalf("unexpected summary after failure: %+v", summary)
	}
}
