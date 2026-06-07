package main

import (
	"fmt"
	"net/http"
	"os"
)

// allowedDataFiles is the exact set of filenames the /api/v1/data/{file}
// endpoint will serve. It acts as the path-traversal guard: only these
// well-known filenames are ever passed to the filesystem.
var allowedDataFiles = map[string]bool{
	"item-data.json":    true,
	"tags-data.json":    true,
	"quality-data.json": true,
	"packs.json":        true,
	"gameplayTags.json": true,
	"skillModules.json": true,
	"vehicles.json":     true,
	"cheatScripts.json": true,
}

// resolveDataFilePathFn is the file-path resolver used by handleGetDataFile.
// Replaced in tests to inject a temp directory without touching the real filesystem.
var resolveDataFilePathFn = resolveDataFilePath

// handleGetDataFile serves the named JSON data file as raw bytes.
// The frontend calls this first; if the file is absent the frontend falls
// back to the CDN. A 404 here is normal and expected.
func handleGetDataFile(w http.ResponseWriter, r *http.Request) {
	name := r.PathValue("file")
	if !allowedDataFiles[name] {
		jsonErr(w, fmt.Errorf("not found"), http.StatusNotFound)
		return
	}
	path := resolveDataFilePathFn(name)
	if path == "" {
		jsonErr(w, fmt.Errorf("not found"), http.StatusNotFound)
		return
	}
	data, err := os.ReadFile(path) // #nosec G304 -- allowlisted filename only; no user input reaches the path
	if err != nil {
		jsonErr(w, fmt.Errorf("not found"), http.StatusNotFound)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	_, _ = w.Write(data)
}
