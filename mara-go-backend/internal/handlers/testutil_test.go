package handlers_test

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/glebarez/sqlite"
	"github.com/go-chi/chi/v5"
	"github.com/mara-app/backend/internal/database"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

// newTestDB opens an in-memory SQLite database and runs migrations.
func newTestDB() *gorm.DB {
	db, err := gorm.Open(sqlite.Open("file::memory:?cache=private&_fk=1"), &gorm.Config{
		Logger: logger.Default.LogMode(logger.Silent),
	})
	if err != nil {
		panic("test db: " + err.Error())
	}
	database.Migrate(db)
	return db
}

// withChiParam injects a chi URL parameter into the request context.
func withChiParam(r *http.Request, key, value string) *http.Request {
	rctx := chi.NewRouteContext()
	rctx.URLParams.Add(key, value)
	return r.WithContext(context.WithValue(r.Context(), chi.RouteCtxKey, rctx))
}

// doRequest fires an HTTP handler with the given body and returns the recorder.
func doRequest(t *testing.T, method, path string, body *bytes.Buffer, handler http.HandlerFunc) *httptest.ResponseRecorder {
	t.Helper()
	var req *http.Request
	if body != nil {
		req = httptest.NewRequest(method, path, body)
	} else {
		req = httptest.NewRequest(method, path, nil)
	}
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	handler(w, req)
	return w
}

// mustJSON marshals v into a *bytes.Buffer.
func mustJSON(t *testing.T, v interface{}) *bytes.Buffer {
	t.Helper()
	b, err := json.Marshal(v)
	if err != nil {
		t.Fatalf("mustJSON: %v", err)
	}
	return bytes.NewBuffer(b)
}

// parseJSON unmarshals raw JSON bytes into dst.
func parseJSON(t *testing.T, raw []byte, dst interface{}) error {
	t.Helper()
	return json.Unmarshal(raw, dst)
}
