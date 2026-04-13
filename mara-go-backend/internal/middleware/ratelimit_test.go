package middleware_test

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/mara-app/backend/internal/middleware"
)

func handler200(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
}

// TestRateLimit verifies that the Rate limiter returns HTTP 429
// after exceeding the 10 req/min threshold from the same IP.
func TestRateLimit_BlocksAfterLimit(t *testing.T) {
	// Build a small chain: RateLimit → 200 handler
	wrapped := middleware.RateLimit(http.HandlerFunc(handler200))

	allowed := 0
	blocked := 0

	for i := 0; i < 15; i++ {
		req := httptest.NewRequest(http.MethodPost, "/login", nil)
		req.Header.Set("X-Real-IP", "192.0.2.1") // fixed IP
		w := httptest.NewRecorder()
		wrapped.ServeHTTP(w, req)
		if w.Code == http.StatusOK {
			allowed++
		} else if w.Code == http.StatusTooManyRequests {
			blocked++
		}
	}

	if allowed != 10 {
		t.Errorf("expected 10 allowed requests, got %d", allowed)
	}
	if blocked != 5 {
		t.Errorf("expected 5 blocked requests (429), got %d", blocked)
	}
}

// TestRateLimit_DifferentIPs verifies that different IPs each get their own budget.
func TestRateLimit_DifferentIPs(t *testing.T) {
	wrapped := middleware.RateLimit(http.HandlerFunc(handler200))

	for _, ip := range []string{"10.0.0.1", "10.0.0.2"} {
		for i := 0; i < 5; i++ {
			req := httptest.NewRequest(http.MethodPost, "/login", nil)
			req.Header.Set("X-Real-IP", ip)
			w := httptest.NewRecorder()
			wrapped.ServeHTTP(w, req)
			if w.Code != http.StatusOK {
				t.Errorf("IP %s req %d: expected 200, got %d", ip, i+1, w.Code)
			}
		}
	}
}

// TestRateLimit_Retry_After verifies that the Retry-After header is set.
func TestRateLimit_RetryAfterHeader(t *testing.T) {
	wrapped := middleware.RateLimit(http.HandlerFunc(handler200))

	for i := 0; i < 11; i++ {
		req := httptest.NewRequest(http.MethodPost, "/login", nil)
		req.Header.Set("X-Real-IP", "192.0.2.99")
		w := httptest.NewRecorder()
		wrapped.ServeHTTP(w, req)
		if w.Code == http.StatusTooManyRequests {
			if w.Header().Get("Retry-After") == "" {
				t.Error("expected Retry-After header on 429 response")
			}
			return
		}
	}
	t.Error("expected at least one 429 response")
}
