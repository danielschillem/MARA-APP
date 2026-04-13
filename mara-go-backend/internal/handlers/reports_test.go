package handlers_test

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/mara-app/backend/internal/handlers"
	ws "github.com/mara-app/backend/internal/websocket"
)

func newReportHandler() *handlers.ReportHandler {
	hub := ws.NewHub()
	return handlers.NewReportHandler(newTestDB(), hub)
}

// ── Public report submission (JSON body) ──────────────────────────────────────

func TestReportStore_MinimalJSON(t *testing.T) {
	h := newReportHandler()
	body := mustJSON(t, map[string]interface{}{
		"reporter_type": "anonymous",
		"region":        "Centre",
		"zone":          "Ouagadougou, Secteur 4",
		"type_id":       "physical",
		"victim_gender": "woman",
	})

	w := doRequest(t, http.MethodPost, "/reports", body, h.Store)
	if w.Code != http.StatusCreated {
		t.Fatalf("expected 201, got %d — body: %s", w.Code, w.Body.String())
	}
}

func TestReportStore_WithCoordinates(t *testing.T) {
	h := newReportHandler()
	body := mustJSON(t, map[string]interface{}{
		"reporter_type": "anonymous",
		"region":        "Sahel",
		"zone":          "Dori",
		"type_id":       "domestic",
		"victim_gender": "child",
		"lat":           14.039,
		"lng":           -0.034,
	})

	w := doRequest(t, http.MethodPost, "/reports", body, h.Store)
	if w.Code != http.StatusCreated {
		t.Fatalf("expected 201, got %d — body: %s", w.Code, w.Body.String())
	}
}

// ── Track report by reference ─────────────────────────────────────────────────

func TestReportTrack_NotFound(t *testing.T) {
	h := newReportHandler()
	req := httptest.NewRequest(http.MethodGet, "/reports/track/INVALID-REF", nil)
	req = withChiParam(req, "reference", "INVALID-REF")
	w := httptest.NewRecorder()
	h.Track(w, req)
	if w.Code != http.StatusNotFound {
		t.Fatalf("expected 404, got %d", w.Code)
	}
}

func TestReportTrack_Found(t *testing.T) {
	h := newReportHandler()

	// Create a report and get back its reference
	cr := doRequest(t, http.MethodPost, "/reports", mustJSON(t, map[string]interface{}{
		"reporter_type": "anonymous",
		"region":        "Centre",
		"zone":          "Bobo",
		"type_id":       "physical",
		"victim_gender": "man",
	}), h.Store)
	if cr.Code != http.StatusCreated {
		t.Fatalf("setup failed: %d %s", cr.Code, cr.Body.String())
	}

	var resp map[string]interface{}
	if err := parseJSON(t, cr.Body.Bytes(), &resp); err != nil {
		t.Fatal(err)
	}
	ref, _ := resp["reference"].(string)
	if ref == "" {
		t.Fatal("no reference in response")
	}

	// Track it
	req := httptest.NewRequest(http.MethodGet, "/reports/track/"+ref, nil)
	req = withChiParam(req, "reference", ref)
	wr := httptest.NewRecorder()
	h.Track(wr, req)
	if wr.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d — %s", wr.Code, wr.Body.String())
	}
}
