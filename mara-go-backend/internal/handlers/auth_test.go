package handlers_test

import (
	"encoding/json"
	"net/http"
	"testing"

	"github.com/mara-app/backend/internal/handlers"
)

const testSecret = "test-secret-minimum-32-chars-padding!!"

// helper: create an AuthHandler backed by an in-memory DB.
func newAuthHandler() *handlers.AuthHandler {
	return handlers.NewAuthHandler(newTestDB(), testSecret)
}

// ── Register ──────────────────────────────────────────────────────────────────

func TestRegister_Success(t *testing.T) {
	h := newAuthHandler()
	body := mustJSON(t, map[string]string{
		"name": "Alice", "email": "alice@test.com", "password": "secure123",
	})

	w := doRequest(t, http.MethodPost, "/register", body, h.Register)

	if w.Code != http.StatusCreated {
		t.Fatalf("expected 201, got %d — body: %s", w.Code, w.Body.String())
	}
	var resp map[string]interface{}
	json.Unmarshal(w.Body.Bytes(), &resp)
	if resp["token"] == nil {
		t.Fatal("expected token in response")
	}
}

func TestRegister_MissingFields(t *testing.T) {
	h := newAuthHandler()
	body := mustJSON(t, map[string]string{"email": "x@x.com"}) // no name/password

	w := doRequest(t, http.MethodPost, "/register", body, h.Register)
	if w.Code != http.StatusBadRequest {
		t.Fatalf("expected 400, got %d", w.Code)
	}
}

func TestRegister_ShortPassword(t *testing.T) {
	h := newAuthHandler()
	body := mustJSON(t, map[string]string{
		"name": "Alice", "email": "alice@test.com", "password": "abc",
	})

	w := doRequest(t, http.MethodPost, "/register", body, h.Register)
	if w.Code != http.StatusBadRequest {
		t.Fatalf("expected 400, got %d", w.Code)
	}
}

func TestRegister_DuplicateEmail(t *testing.T) {
	h := newAuthHandler()
	body := mustJSON(t, map[string]string{
		"name": "Alice", "email": "alice@test.com", "password": "secure123",
	})

	doRequest(t, http.MethodPost, "/register", body, h.Register)
	body2 := mustJSON(t, map[string]string{
		"name": "Alice2", "email": "alice@test.com", "password": "secure456",
	})
	w := doRequest(t, http.MethodPost, "/register", body2, h.Register)
	if w.Code != http.StatusConflict {
		t.Fatalf("expected 409, got %d", w.Code)
	}
}

// ── Login ─────────────────────────────────────────────────────────────────────

func TestLogin_Success(t *testing.T) {
	h := newAuthHandler()
	// Register first
	doRequest(t, http.MethodPost, "/register", mustJSON(t, map[string]string{
		"name": "Bob", "email": "bob@test.com", "password": "password123",
	}), h.Register)

	// Login
	w := doRequest(t, http.MethodPost, "/login", mustJSON(t, map[string]string{
		"email": "bob@test.com", "password": "password123",
	}), h.Login)

	if w.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d — body: %s", w.Code, w.Body.String())
	}
	var resp map[string]interface{}
	json.Unmarshal(w.Body.Bytes(), &resp)
	if resp["token"] == nil {
		t.Fatal("expected JWT token in login response")
	}
}

func TestLogin_WrongPassword(t *testing.T) {
	h := newAuthHandler()
	doRequest(t, http.MethodPost, "/register", mustJSON(t, map[string]string{
		"name": "Bob", "email": "bob@test.com", "password": "password123",
	}), h.Register)

	w := doRequest(t, http.MethodPost, "/login", mustJSON(t, map[string]string{
		"email": "bob@test.com", "password": "wrongpassword",
	}), h.Login)

	if w.Code != http.StatusUnauthorized {
		t.Fatalf("expected 401, got %d", w.Code)
	}
}

func TestLogin_UnknownUser(t *testing.T) {
	h := newAuthHandler()
	w := doRequest(t, http.MethodPost, "/login", mustJSON(t, map[string]string{
		"email": "ghost@test.com", "password": "password123",
	}), h.Login)

	if w.Code != http.StatusUnauthorized {
		t.Fatalf("expected 401, got %d", w.Code)
	}
}

// ensure ws package compiles in test context (no-op reference removed)
