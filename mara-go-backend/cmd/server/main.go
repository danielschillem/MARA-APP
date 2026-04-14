package main

import (
	"fmt"
	"log/slog"
	"net/http"
	"os"

	"github.com/go-chi/chi/v5"
	chimw "github.com/go-chi/chi/v5/middleware"
	"github.com/go-chi/cors"
	"github.com/joho/godotenv"

	"github.com/mara-app/backend/internal/config"
	"github.com/mara-app/backend/internal/database"
	"github.com/mara-app/backend/internal/handlers"
	authmw "github.com/mara-app/backend/internal/middleware"
	"github.com/mara-app/backend/internal/models"
	ws "github.com/mara-app/backend/internal/websocket"
)

func main() {
	// Load .env if present
	godotenv.Load()

	cfg := config.Load()

	// Configure structured logger
	logLevel := slog.LevelInfo
	if cfg.Environment == "development" {
		logLevel = slog.LevelDebug
	}
	slog.SetDefault(slog.New(slog.NewTextHandler(os.Stdout, &slog.HandlerOptions{Level: logLevel})))
	db := database.Connect(cfg.DatabaseURL)

	// Seed on first run
	if seed := os.Getenv("DB_SEED"); seed == "true" {
		database.Seed(db)
	}

	// WebSocket hub
	hub := ws.NewHub()
	go hub.Run()

	// Handlers
	authH := handlers.NewAuthHandler(db, cfg.JWTSecret)
	reportH := handlers.NewReportHandler(db, hub)
	alertH := handlers.NewAlertHandler(db, hub)
	convH := handlers.NewConversationHandler(db, hub)
	dashH := handlers.NewDashboardHandler(db)
	dirH := handlers.NewDirectoryHandler(db)
	resH := handlers.NewResourceHandler(db)
	teamH := handlers.NewTeamHandler(db)
	obsH := handlers.NewObservatoryHandler(db, cfg.ReliefWebURL)
	userH := handlers.NewUserHandler(db)
	annH := handlers.NewAnnouncementHandler(db)

	r := chi.NewRouter()

	// Global middleware
	r.Use(chimw.Logger)
	r.Use(chimw.Recoverer)
	r.Use(chimw.RequestID)
	r.Use(authmw.SecureHeaders)
	r.Use(cors.Handler(cors.Options{
		AllowedOrigins: []string{
			cfg.FrontendURL,
			cfg.FlutterURL,
			"http://localhost:*",
			"http://127.0.0.1:*",
			"https://*.netlify.app",
			"https://mara-app-production.netlify.app",
		},
		AllowedMethods:   []string{"GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"},
		AllowedHeaders:   []string{"Accept", "Authorization", "Content-Type", "X-Request-ID"},
		AllowCredentials: true,
		MaxAge:           300,
	}))

	r.Route("/api", func(r chi.Router) {
		// ── Health ──────────────────────────────────────────────────────────────
		r.Get("/health", func(w http.ResponseWriter, r *http.Request) {
			sqlDB, err := db.DB()
			dbStatus := "ok"
			if err != nil || sqlDB.Ping() != nil {
				dbStatus = "degraded"
			}
			w.Header().Set("Content-Type", "application/json")
			if dbStatus == "degraded" {
				w.WriteHeader(http.StatusServiceUnavailable)
			}
			fmt.Fprintf(w, `{"status":"ok","db":"%s","app":"MARA API","version":"2.0.0"}`, dbStatus)
		})

		// ── Auth (rate limited) ───────────────────────────────────────────────────
		r.With(authmw.RateLimit).Post("/register", authH.Register)
		r.With(authmw.RateLimit).Post("/login", authH.Login)
		r.Post("/refresh-token", authH.RefreshToken)

		// ── Public data ──────────────────────────────────────────────────────────
		r.Get("/violence-types", dirH.ViolenceTypes)
		r.Get("/sos-numbers", dirH.SosNumbers)
		r.Get("/services", dirH.Services)
		r.Get("/resources", resH.Index)
		r.Get("/resources/{id}", resH.Show)
		r.Get("/announcements", annH.Index)

		// ── Public reports ───────────────────────────────────────────────────────
		r.Post("/reports", reportH.Store)
		r.Get("/reports/track/{reference}", reportH.Track)

		// ── Public alerts (citizen app) ──────────────────────────────────────────
		r.Post("/alerts", alertH.Store)
		r.Get("/alerts/map", alertH.MapData)

		// ── Anonymous conversations ──────────────────────────────────────────────
		r.Post("/conversations/anonymous", convH.StartAnonymous)
		r.Get("/conversations/{id}", convH.Show)
		r.Get("/conversations/{id}/messages", convH.Messages)
		r.Post("/conversations/{id}/messages", convH.SendMessage)

		// ── Public Observatory ───────────────────────────────────────────────────
		r.Get("/observatory/stats", obsH.Stats)
		r.Get("/observatory/reliefweb", obsH.ReliefWeb)

		// ── WebSocket ─────────────────────────────────────────────────────────────
		r.Get("/ws", hub.ServeWS)

		// ── Protected routes ──────────────────────────────────────────────────────
		r.Group(func(r chi.Router) {
			r.Use(authmw.Auth(cfg.JWTSecret))

			r.Post("/logout", authH.Logout)
			r.Get("/me", authH.Me)
			r.Put("/me", authH.UpdateProfile)
			r.Post("/change-password", authH.ChangePassword)

			// Dashboard
			r.Get("/dashboard", dashH.Index)

			// Reports management
			r.Get("/reports", reportH.Index)
			r.Get("/reports/stats", reportH.Stats)
			r.Get("/reports/export", reportH.Export)
			r.Get("/reports/{id}", reportH.Show)
			r.Put("/reports/{id}", reportH.Update)
			r.Post("/reports/{id}/assign", reportH.Assign)

			// Observatory admin (force sync)
			r.With(authmw.RequireRole(models.RoleAdmin)).Post("/observatory/reliefweb/sync", obsH.SyncReliefWeb)

			// Admin — user management + services + SOS + announcements
			r.Group(func(r chi.Router) {
				r.Use(authmw.RequireRole(models.RoleAdmin))
				r.Get("/admin/users", userH.Index)
				r.Post("/admin/users", userH.Store)
				r.Put("/admin/users/{id}", userH.Update)
				r.Delete("/admin/users/{id}", userH.Destroy)

				// Services CRUD
				r.Post("/admin/services", dirH.ServiceStore)
				r.Put("/admin/services/{id}", dirH.ServiceUpdate)
				r.Delete("/admin/services/{id}", dirH.ServiceDestroy)

				// SOS Numbers CRUD
				r.Post("/admin/sos-numbers", dirH.SosStore)
				r.Put("/admin/sos-numbers/{id}", dirH.SosUpdate)
				r.Delete("/admin/sos-numbers/{id}", dirH.SosDestroy)

				// Announcements CRUD
				r.Get("/admin/announcements", annH.AdminIndex)
				r.Post("/admin/announcements", annH.Store)
				r.Put("/admin/announcements/{id}", annH.Update)
				r.Delete("/admin/announcements/{id}", annH.Destroy)
			})

			// Alerts (VeilleProtect coordinator)
			r.Get("/alerts", alertH.Index)
			r.Get("/alerts/dashboard", alertH.Dashboard)
			r.Get("/alerts/{id}", alertH.Show)
			r.Put("/alerts/{id}", alertH.Update)
			r.Post("/alerts/{id}/assign", alertH.Assign)

			// Conversations management
			r.Get("/conversations", convH.Index)
			r.Post("/conversations", convH.Store)
			r.Post("/conversations/{id}/assign", convH.Assign)
			r.Post("/conversations/{id}/close", convH.Close)

			// Resources management (admin/pro only)
			r.Group(func(r chi.Router) {
				r.Use(authmw.RequireRole(models.RoleAdmin, models.RoleProfessional))
				r.Post("/resources", resH.Store)
				r.Put("/resources/{id}", resH.Update)
				r.Delete("/resources/{id}", resH.Destroy)
			})

			// Team management (coordinator dashboard)
			r.Get("/team", teamH.Index)
			r.Put("/team/{id}/status", teamH.UpdateStatus)
		})
	})

	// Static file server for uploads
	r.Get("/uploads/*", func(w http.ResponseWriter, r *http.Request) {
		http.StripPrefix("/uploads/", http.FileServer(http.Dir("uploads"))).ServeHTTP(w, r)
	})

	addr := ":" + cfg.Port
	slog.Info("MARA Go API v2.0 starting", "addr", addr, "env", cfg.Environment)
	if err := http.ListenAndServe(addr, r); err != nil {
		slog.Error("server error", "err", err)
		os.Exit(1)
	}
}
