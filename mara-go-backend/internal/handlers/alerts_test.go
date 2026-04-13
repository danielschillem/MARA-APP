package handlers_test

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/mara-app/backend/internal/handlers"
	ws "github.com/mara-app/backend/internal/websocket"
)

func newAlertHandler() *handlers.AlertHandler {
	hub := ws.NewHub()
	return handlers.NewAlertHandler(newTestDB(), hub)
}

// ── Store alert ───────────────────────────────────────────────────────────────

func TestAlertStore_Success(t *testing.T) {
	h := newAlertHandler()
	body := mustJSON(t, map[string]interface{}{
		"type_id":      "physical",
		"victim_type":  "woman",
		"lat":          12.364,
		"lng":          -1.534,
		"zone":         "Ouagadougou Centre",
		"is_ongoing":   true,
		"is_anonymous": true,
		"channel":      "app",
	})

	w := doRequest(t, http.MethodPost, "/alerts", body, h.Store)
	if w.Code != http.StatusCreated {
		t.Fatalf("expected 201, got %d — body: %s", w.Code, w.Body.String())
	}

	var resp map[string]interface{}
	if err := parseJSON(t, w.Body.Bytes(), &resp); err != nil {
		t.Fatal(err)
	}
	// Ongoing alert should be set to critical severity
	if resp["severity"] != "critical" {
		t.Errorf("expected severity=critical for ongoing alert, got %v", resp["severity"])
	}
}

func TestAlertStore_NonOngoing_DefaultSeverity(t *testing.T) {
	h := newAlertHandler()
	body := mustJSON(t, map[string]interface{}{
		"type_id":     "verbal",
		"victim_type": "man",
		"zone":        "Bobo-Dioulasso",
		"is_ongoing":  false,
	})

	w := doRequest(t, http.MethodPost, "/alerts", body, h.Store)
	if w.Code != http.StatusCreated {
		t.Fatalf("expected 201, got %d — %s", w.Code, w.Body.String())
	}

	var resp map[string]interface{}
	parseJSON(t, w.Body.Bytes(), &resp)
	// Non-ongoing should default to medium
	if resp["severity"] != "medium" {
		t.Errorf("expected severity=medium, got %v", resp["severity"])
	}
}

// ── Map data ──────────────────────────────────────────────────────────────────

func TestAlertMapData(t *testing.T) {
	h := newAlertHandler()

	// Seed two alerts
	for _, zone := range []string{"Zone A", "Zone B"} {
		doRequest(t, http.MethodPost, "/alerts", mustJSON(t, map[string]interface{}{
			"type_id":     "physical",
			"victim_type": "child",
			"zone":        zone,
		}), h.Store)
	}

	req := httptest.NewRequest(http.MethodGet, "/alerts/map", nil)
	w := httptest.NewRecorder()
	h.MapData(w, req)

	if w.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d", w.Code)
	}

	var alerts []map[string]interface{}
	if err := parseJSON(t, w.Body.Bytes(), &alerts); err != nil {
		t.Fatal(err)
	}
	if len(alerts) < 2 {
		t.Errorf("expected at least 2 alerts in map data, got %d", len(alerts))
	}
}
