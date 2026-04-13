package config

import (
	"os"
	"strconv"
)

type Config struct {
	Port         string
	DatabaseURL  string
	JWTSecret    string
	FrontendURL  string
	FlutterURL   string
	Environment  string
	MaxUploadMB  int64
	ReliefWebURL string
}

func Load() *Config {
	return &Config{
		Port:         getEnv("PORT", "8081"),
		DatabaseURL:  getEnv("DATABASE_URL", "file:mara.db?cache=shared&mode=rwc"),
		JWTSecret:    getEnv("JWT_SECRET", "changeme-secret-key-32-chars-min!!"),
		FrontendURL:  getEnv("FRONTEND_URL", "http://localhost:5173"),
		FlutterURL:   getEnv("FLUTTER_URL", "http://localhost:3000"),
		Environment:  getEnv("APP_ENV", "development"),
		MaxUploadMB:  getEnvInt64("MAX_UPLOAD_MB", 20),
		ReliefWebURL: getEnv("RELIEFWEB_URL", "https://api.reliefweb.int/v1"),
	}
}

func getEnv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}

func getEnvInt64(key string, fallback int64) int64 {
	if v := os.Getenv(key); v != "" {
		if n, err := strconv.ParseInt(v, 10, 64); err == nil {
			return n
		}
	}
	return fallback
}
