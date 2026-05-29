package main

import (
	"os"
	"path/filepath"
	"testing"
)

func TestResolveAppVersion(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name           string
		ldflagsVersion string
		versionFile    string // empty = don't create
		want           string
	}{
		{
			name:           "ldflags version is used as-is",
			ldflagsVersion: "0.14.2",
			want:           "0.14.2",
		},
		{
			name:           "dev with VERSION file returns version-dev",
			ldflagsVersion: "dev",
			versionFile:    "0.14.2",
			want:           "0.14.2-dev",
		},
		{
			name:           "dev with VERSION file strips trailing newline",
			ldflagsVersion: "dev",
			versionFile:    "0.14.2\n",
			want:           "0.14.2-dev",
		},
		{
			name:           "dev without VERSION file stays dev",
			ldflagsVersion: "dev",
			want:           "dev",
		},
		{
			name:           "dev with empty VERSION file stays dev",
			ldflagsVersion: "dev",
			versionFile:    "   \n",
			want:           "dev",
		},
		{
			name:           "non-dev version ignores VERSION file entirely",
			ldflagsVersion: "0.13.0",
			versionFile:    "0.14.2",
			want:           "0.13.0",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()
			dir := t.TempDir()
			if tt.versionFile != "" {
				if err := os.WriteFile(filepath.Join(dir, "VERSION"), []byte(tt.versionFile), 0644); err != nil {
					t.Fatal(err)
				}
			}
			got := resolveAppVersion(tt.ldflagsVersion, dir)
			if got != tt.want {
				t.Fatalf("resolveAppVersion(%q, dir) = %q, want %q", tt.ldflagsVersion, got, tt.want)
			}
		})
	}
}
