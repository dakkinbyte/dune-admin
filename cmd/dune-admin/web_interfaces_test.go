package main

import "testing"

func TestValidateWebInterfaces(t *testing.T) {
	t.Parallel()
	tests := []struct {
		name string
		in   []webInterface
		ok   bool
	}{
		{"valid mix", []webInterface{{Label: "Director", URL: "/director/"}, {Label: "AMP", URL: "http://host:8080"}}, true},
		{"https ok", []webInterface{{Label: "Panel", URL: "https://example.com/x"}}, true},
		{"empty list ok", []webInterface{}, true},
		{"empty label", []webInterface{{Label: "", URL: "/x"}}, false},
		{"empty url", []webInterface{{Label: "X", URL: ""}}, false},
		{"javascript scheme rejected", []webInterface{{Label: "X", URL: "javascript:alert(1)"}}, false},
		{"bare host rejected", []webInterface{{Label: "X", URL: "host:8080"}}, false},
		{"ftp rejected", []webInterface{{Label: "X", URL: "ftp://h/x"}}, false},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := validateWebInterfaces(tt.in)
			if tt.ok && err != nil {
				t.Fatalf("validateWebInterfaces(%v) = %v, want nil", tt.in, err)
			}
			if !tt.ok && err == nil {
				t.Fatalf("validateWebInterfaces(%v) = nil, want error", tt.in)
			}
		})
	}

	// too many entries rejected
	many := make([]webInterface, maxWebInterfaces+1)
	for i := range many {
		many[i] = webInterface{Label: "L", URL: "/x"}
	}
	if validateWebInterfaces(many) == nil {
		t.Fatalf("expected error for > %d entries", maxWebInterfaces)
	}
}

func TestSeedWebInterfaces(t *testing.T) {
	prev := loadedConfig
	t.Cleanup(func() { loadedConfig = prev })

	loadedConfig = appConfig{DirectorURL: "http://127.0.0.1:11717"}
	seed := seedWebInterfaces()
	if len(seed) != 1 || seed[0].Label != "Director" || seed[0].URL != "/director/" {
		t.Fatalf("with director_url set, seed = %+v, want one Director→/director/ entry", seed)
	}

	loadedConfig = appConfig{DirectorURL: ""}
	if len(seedWebInterfaces()) != 0 {
		t.Fatalf("with no director_url, seed should be empty")
	}
}
