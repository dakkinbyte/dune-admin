package main

import (
	"fmt"
	"log"
	"net/http"
)

// @Summary Landsraad overview — latest term, decree catalogue, and task board
// @Tags landsraad
// @Produce json
// @Success 200 {object} landsraadOverview
// @Failure 500 {object} map[string]string
// @Failure 503 {object} map[string]string
// @Router /api/v1/landsraad [get]
func handleGetLandsraad(w http.ResponseWriter, r *http.Request) {
	if globalDB == nil {
		jsonErr(w, fmt.Errorf("database not connected"), http.StatusServiceUnavailable)
		return
	}
	ov, err := cmdFetchLandsraad(r.Context(), globalDB)
	if err != nil {
		log.Printf("handleGetLandsraad: %v", err)
		jsonErr(w, fmt.Errorf("internal error"), http.StatusInternalServerError)
		return
	}
	jsonOK(w, ov)
}
