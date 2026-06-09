package main

import (
	"fmt"
	"log"
	"net/http"
)

// @Summary List configured web interfaces
// @Tags web-interfaces
// @Produce json
// @Success 200 {object} map[string]interface{}
// @Router /api/v1/web-interfaces [get]
func handleGetWebInterfaces(w http.ResponseWriter, _ *http.Request) {
	jsonOK(w, map[string]any{"interfaces": getWebInterfaces()})
}

// @Summary Replace the configured web interfaces
// @Tags web-interfaces
// @Accept json
// @Produce json
// @Success 200 {object} map[string]string
// @Failure 400 {object} map[string]string
// @Router /api/v1/web-interfaces [put]
func handleUpdateWebInterfaces(w http.ResponseWriter, r *http.Request) {
	var body struct {
		Interfaces []webInterface `json:"interfaces"`
	}
	if err := decode(r, &body); err != nil {
		jsonErr(w, err, http.StatusBadRequest)
		return
	}
	if err := validateWebInterfaces(body.Interfaces); err != nil {
		jsonErr(w, err, http.StatusBadRequest)
		return
	}
	if err := saveWebInterfaces(body.Interfaces); err != nil {
		log.Printf("handleUpdateWebInterfaces: %v", err)
		jsonErr(w, fmt.Errorf("could not save web interfaces"), http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]string{"ok": "web interfaces saved"})
}
