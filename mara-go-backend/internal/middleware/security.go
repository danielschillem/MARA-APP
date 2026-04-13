package middleware

import "net/http"

// SecureHeaders adds OWASP-recommended security response headers.
// Covers: A05 Security Misconfiguration, A07 Identification Failures (clickjacking/MIME sniff).
func SecureHeaders(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		h := w.Header()

		// Prevent MIME type sniffing (OWASP A05)
		h.Set("X-Content-Type-Options", "nosniff")

		// Clickjacking protection (OWASP A05)
		h.Set("X-Frame-Options", "DENY")

		// Block XSS in older browsers (defence-in-depth)
		h.Set("X-XSS-Protection", "1; mode=block")

		// Force HTTPS in production (OWASP A02)
		h.Set("Strict-Transport-Security", "max-age=63072000; includeSubDomains")

		// Control referrer information leakage
		h.Set("Referrer-Policy", "strict-origin-when-cross-origin")

		// Restrict browser features (OWASP A05)
		h.Set("Permissions-Policy", "geolocation=(), microphone=(), camera=()")

		// Content-Security-Policy — allows API self + WS connections
		// Frontend is served separately; this policy covers the API's own JSON responses.
		h.Set("Content-Security-Policy",
			"default-src 'none'; frame-ancestors 'none'")

		next.ServeHTTP(w, r)
	})
}
