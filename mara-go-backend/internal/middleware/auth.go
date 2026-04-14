package middleware

import (
	"context"
	"net/http"
	"strings"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/mara-app/backend/internal/models"
)

type contextKey string

const UserKey contextKey = "user"

type Claims struct {
	UserID    uint            `json:"user_id"`
	Role      models.UserRole `json:"role"`
	TokenType string          `json:"token_type,omitempty"` // "access" | "refresh"
	jwt.RegisteredClaims
}

func GenerateToken(user *models.User, secret string) (string, error) {
	claims := Claims{
		UserID:    user.ID,
		Role:      user.Role,
		TokenType: "access",
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(24 * time.Hour)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
		},
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(secret))
}

func GenerateRefreshToken(user *models.User, secret string) (string, error) {
	claims := Claims{
		UserID:    user.ID,
		Role:      user.Role,
		TokenType: "refresh",
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(30 * 24 * time.Hour)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
		},
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(secret))
}

func ParseToken(tokenStr, secret string) (*Claims, error) {
	token, err := jwt.ParseWithClaims(tokenStr, &Claims{}, func(t *jwt.Token) (interface{}, error) {
		return []byte(secret), nil
	})
	if err != nil {
		return nil, err
	}
	if claims, ok := token.Claims.(*Claims); ok && token.Valid {
		return claims, nil
	}
	return nil, jwt.ErrTokenInvalidClaims
}

// Auth middleware — attaches user claims to context, returns 401 if missing/invalid
func Auth(secret string) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			authHeader := r.Header.Get("Authorization")
			if authHeader == "" || !strings.HasPrefix(authHeader, "Bearer ") {
				http.Error(w, `{"error":"unauthorized"}`, http.StatusUnauthorized)
				return
			}
			tokenStr := strings.TrimPrefix(authHeader, "Bearer ")
			claims, err := ParseToken(tokenStr, secret)
			if err != nil {
				http.Error(w, `{"error":"invalid token"}`, http.StatusUnauthorized)
				return
			}
			ctx := context.WithValue(r.Context(), UserKey, claims)
			next.ServeHTTP(w, r.WithContext(ctx))
		})
	}
}

// RequireRole returns 403 if user doesn't have one of the given roles
func RequireRole(roles ...models.UserRole) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			claims, ok := r.Context().Value(UserKey).(*Claims)
			if !ok {
				http.Error(w, `{"error":"unauthorized"}`, http.StatusUnauthorized)
				return
			}
			for _, role := range roles {
				if claims.Role == role {
					next.ServeHTTP(w, r)
					return
				}
			}
			http.Error(w, `{"error":"forbidden"}`, http.StatusForbidden)
		})
	}
}

func ClaimsFromCtx(r *http.Request) *Claims {
	claims, _ := r.Context().Value(UserKey).(*Claims)
	return claims
}
