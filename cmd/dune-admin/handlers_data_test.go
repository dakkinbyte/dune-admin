package main

import (
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"testing"
)

// ── allowlist enforcement ─────────────────────────────────────────────────────

func TestHandleGetDataFile_NonAllowlistedReturns404(t *testing.T) {
	tests := []struct {
		name     string
		filename string
	}{
		{"path traversal", "../config.yaml"},
		{"unknown json", "secrets.json"},
		{"dot-env", ".env"},
		{"go source", "main.go"},
		{"empty string", ""},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			req := httptest.NewRequest(http.MethodGet, "/api/v1/data/"+tt.filename, nil)
			req.SetPathValue("file", tt.filename)
			rec := httptest.NewRecorder()
			handleGetDataFile(rec, req)
			if rec.Code != http.StatusNotFound {
				t.Fatalf("want 404 for %q, got %d", tt.filename, rec.Code)
			}
		})
	}
}

// ── file-absent path ──────────────────────────────────────────────────────────

func TestHandleGetDataFile_AllowlistedFileAbsent(t *testing.T) {
	// Not parallel: mutates resolveDataFilePathFn.
	orig := resolveDataFilePathFn
	resolveDataFilePathFn = func(string) string { return "" }
	t.Cleanup(func() { resolveDataFilePathFn = orig })

	req := httptest.NewRequest(http.MethodGet, "/api/v1/data/item-data.json", nil)
	req.SetPathValue("file", "item-data.json")
	rec := httptest.NewRecorder()
	handleGetDataFile(rec, req)
	if rec.Code != http.StatusNotFound {
		t.Fatalf("want 404, got %d", rec.Code)
	}
}

// ── file-present path ─────────────────────────────────────────────────────────

func TestHandleGetDataFile_AllowlistedFilePresent(t *testing.T) {
	// Not parallel: mutates resolveDataFilePathFn.
	tmpDir := t.TempDir()
	content := []byte(`{"items":{}}`)
	if err := os.WriteFile(filepath.Join(tmpDir, "item-data.json"), content, 0600); err != nil {
		t.Fatal(err)
	}

	orig := resolveDataFilePathFn
	resolveDataFilePathFn = func(name string) string { return filepath.Join(tmpDir, name) }
	t.Cleanup(func() { resolveDataFilePathFn = orig })

	req := httptest.NewRequest(http.MethodGet, "/api/v1/data/item-data.json", nil)
	req.SetPathValue("file", "item-data.json")
	rec := httptest.NewRecorder()
	handleGetDataFile(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("want 200, got %d (body: %s)", rec.Code, rec.Body.String())
	}
	if ct := rec.Header().Get("Content-Type"); ct != "application/json" {
		t.Fatalf("want Content-Type application/json, got %q", ct)
	}
	if got := rec.Body.Bytes(); string(got) != string(content) {
		t.Fatalf("want body %q, got %q", content, got)
	}
}

// TestHandleGetDataFile_AllEightFilesServed verifies every file in the allowlist
// passes through the allowlist check and is served raw when present.
func TestHandleGetDataFile_AllEightFilesServed(t *testing.T) {
	// Not parallel: mutates resolveDataFilePathFn.
	tmpDir := t.TempDir()

	wantFiles := []string{
		"item-data.json",
		"tags-data.json",
		"quality-data.json",
		"packs.json",
		"gameplayTags.json",
		"skillModules.json",
		"vehicles.json",
		"cheatScripts.json",
	}
	payload := []byte(`["sentinel"]`)
	for _, f := range wantFiles {
		if err := os.WriteFile(filepath.Join(tmpDir, f), payload, 0600); err != nil {
			t.Fatal(err)
		}
	}

	orig := resolveDataFilePathFn
	resolveDataFilePathFn = func(name string) string { return filepath.Join(tmpDir, name) }
	t.Cleanup(func() { resolveDataFilePathFn = orig })

	for _, f := range wantFiles {
		req := httptest.NewRequest(http.MethodGet, "/api/v1/data/"+f, nil)
		req.SetPathValue("file", f)
		rec := httptest.NewRecorder()
		handleGetDataFile(rec, req)
		if rec.Code != http.StatusOK {
			t.Errorf("%s: want 200, got %d (body: %s)", f, rec.Code, rec.Body.String())
			continue
		}
		if got := rec.Body.String(); got != string(payload) {
			t.Errorf("%s: want body %q, got %q", f, payload, got)
		}
	}
}

// ── firstExistingPath ─────────────────────────────────────────────────────────

func TestFirstExistingPath_ReturnsFirstMatch(t *testing.T) {
	t.Parallel()
	dir1 := t.TempDir()
	dir2 := t.TempDir()

	// Only dir2 has the file — should skip dir1 and return dir2.
	if err := os.WriteFile(filepath.Join(dir2, "data.json"), []byte("{}"), 0600); err != nil {
		t.Fatal(err)
	}

	got := firstExistingPath([]string{
		filepath.Join(dir1, "data.json"),
		filepath.Join(dir2, "data.json"),
	})
	want := filepath.Join(dir2, "data.json")
	if got != want {
		t.Fatalf("want %q, got %q", want, got)
	}
}

func TestFirstExistingPath_PrefersEarlierCandidate(t *testing.T) {
	t.Parallel()
	dir1 := t.TempDir()
	dir2 := t.TempDir()

	// Both dirs have the file — should return dir1 (first in list).
	for _, d := range []string{dir1, dir2} {
		if err := os.WriteFile(filepath.Join(d, "data.json"), []byte("{}"), 0600); err != nil {
			t.Fatal(err)
		}
	}

	got := firstExistingPath([]string{
		filepath.Join(dir1, "data.json"),
		filepath.Join(dir2, "data.json"),
	})
	want := filepath.Join(dir1, "data.json")
	if got != want {
		t.Fatalf("want %q (first match), got %q", want, got)
	}
}

func TestFirstExistingPath_NoneExist(t *testing.T) {
	t.Parallel()
	dir := t.TempDir()
	got := firstExistingPath([]string{
		filepath.Join(dir, "absent1.json"),
		filepath.Join(dir, "absent2.json"),
	})
	if got != "" {
		t.Fatalf("want empty string, got %q", got)
	}
}

func TestFirstExistingPath_EmptyCandidateList(t *testing.T) {
	t.Parallel()
	got := firstExistingPath(nil)
	if got != "" {
		t.Fatalf("want empty string, got %q", got)
	}
}
