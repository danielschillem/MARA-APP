package middleware

import (
	"net/http"
	"sync"
	"time"
)

type rateLimiter struct {
	mu       sync.Mutex
	attempts map[string][]time.Time
	max      int
	window   time.Duration
}

func newRateLimiter(max int, window time.Duration) *rateLimiter {
	rl := &rateLimiter{
		attempts: make(map[string][]time.Time),
		max:      max,
		window:   window,
	}
	// Cleanup goroutine
	go func() {
		for range time.Tick(5 * time.Minute) {
			rl.mu.Lock()
			cutoff := time.Now().Add(-window)
			for key, times := range rl.attempts {
				filtered := times[:0]
				for _, t := range times {
					if t.After(cutoff) {
						filtered = append(filtered, t)
					}
				}
				if len(filtered) == 0 {
					delete(rl.attempts, key)
				} else {
					rl.attempts[key] = filtered
				}
			}
			rl.mu.Unlock()
		}
	}()
	return rl
}

func (rl *rateLimiter) allow(key string) bool {
	rl.mu.Lock()
	defer rl.mu.Unlock()

	now := time.Now()
	cutoff := now.Add(-rl.window)

	// Keep only attempts within the window
	var recent []time.Time
	for _, t := range rl.attempts[key] {
		if t.After(cutoff) {
			recent = append(recent, t)
		}
	}

	if len(recent) >= rl.max {
		rl.attempts[key] = recent
		return false
	}

	rl.attempts[key] = append(recent, now)
	return true
}

// Global rate limiters
var (
	authLimiter = newRateLimiter(10, time.Minute) // 10 attempts/min per IP
)

// RateLimit middleware — limits requests per IP on sensitive routes
func RateLimit(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		ip := realIP(r)
		if !authLimiter.allow(ip) {
			w.Header().Set("Retry-After", "60")
			http.Error(w, `{"error":"too many requests, please wait"}`, http.StatusTooManyRequests)
			return
		}
		next.ServeHTTP(w, r)
	})
}

func realIP(r *http.Request) string {
	if ip := r.Header.Get("X-Real-IP"); ip != "" {
		return ip
	}
	if ip := r.Header.Get("X-Forwarded-For"); ip != "" {
		// Take the first IP in the chain
		for i, ch := range ip {
			if ch == ',' {
				return ip[:i]
			}
		}
		return ip
	}
	return r.RemoteAddr
}
