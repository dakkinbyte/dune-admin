package main

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	_ "dune-admin/docs"
	httpSwagger "github.com/swaggo/http-swagger/v2"
)

func TestSwaggerUI(t *testing.T) {
	mux := http.NewServeMux()
	mux.Handle("/swagger/", httpSwagger.WrapHandler)

	req := httptest.NewRequest(http.MethodGet, "/swagger/index.html", nil)
	w := httptest.NewRecorder()
	mux.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Errorf("swagger index returned %d, want 200", w.Code)
	}
	ct := w.Header().Get("Content-Type")
	if !strings.Contains(ct, "text/html") {
		t.Errorf("content-type = %q, want text/html", ct)
	}
}

func TestSwaggerDocJSON(t *testing.T) {
	mux := http.NewServeMux()
	mux.Handle("/swagger/", httpSwagger.WrapHandler)

	req := httptest.NewRequest(http.MethodGet, "/swagger/doc.json", nil)
	w := httptest.NewRecorder()
	mux.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Errorf("swagger doc.json returned %d, want 200", w.Code)
	}
	ct := w.Header().Get("Content-Type")
	if !strings.Contains(ct, "application/json") {
		t.Errorf("content-type = %q, want application/json", ct)
	}
}
