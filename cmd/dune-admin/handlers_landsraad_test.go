package main

import (
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestLandsraadHouseName(t *testing.T) {
	t.Parallel()
	tests := []struct{ name, in, want string }{
		{"strips DA_House prefix", "DA_HouseHagal", "Hagal"},
		{"strips prefix Moritani", "DA_HouseMoritani", "Moritani"},
		{"unprefixed passes through", "Corrino", "Corrino"},
		{"empty stays empty", "", ""},
	}
	for _, tt := range tests {
		tt := tt
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()
			if got := landsraadHouseName(tt.in); got != tt.want {
				t.Fatalf("landsraadHouseName(%q) = %q, want %q", tt.in, got, tt.want)
			}
		})
	}
}

func TestHandleGetLandsraad_DBNil(t *testing.T) {
	orig := globalDB
	globalDB = nil
	defer func() { globalDB = orig }()

	req := httptest.NewRequest(http.MethodGet, "/api/v1/landsraad", nil)
	rr := httptest.NewRecorder()
	handleGetLandsraad(rr, req)

	if rr.Code != http.StatusServiceUnavailable {
		t.Fatalf("want 503, got %d", rr.Code)
	}
}
