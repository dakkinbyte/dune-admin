package main

import "testing"

func TestIsReadOnlySQL(t *testing.T) {
	tests := []struct {
		name string
		sql  string
		want bool
	}{
		{"select uppercase", "SELECT * FROM players", true},
		{"select lowercase", "select id from players", true},
		{"select leading whitespace", "  SELECT 1", true},
		{"explain allowed", "EXPLAIN SELECT * FROM players", true},
		{"show allowed", "SHOW TABLES", true},
		{"update blocked", "UPDATE players SET x=1", false},
		{"delete blocked", "DELETE FROM players", false},
		{"insert blocked", "INSERT INTO players VALUES (1)", false},
		{"drop blocked", "DROP TABLE players", false},
		{"truncate blocked", "TRUNCATE players", false},
		{"line comment stripped, select kept", "-- comment\nSELECT 1", true},
		{"block comment stripped, select kept", "/* comment */ SELECT 1", true},
		{"block comment disguises write", "/* SELECT */ UPDATE players SET x=1", false},
		{"multiline block comment", "/*\n multi\n line\n*/SELECT 1", true},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := isReadOnlySQL(tt.sql); got != tt.want {
				t.Errorf("isReadOnlySQL(%q) = %v, want %v", tt.sql, got, tt.want)
			}
		})
	}
}
