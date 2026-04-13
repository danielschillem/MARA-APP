package handlers

import (
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/mara-app/backend/internal/models"
	"gorm.io/gorm"
)

type TeamHandler struct {
	db *gorm.DB
}

func NewTeamHandler(db *gorm.DB) *TeamHandler {
	return &TeamHandler{db: db}
}

// GET /team — list all coordinators
func (h *TeamHandler) Index(w http.ResponseWriter, r *http.Request) {
	var users []models.User
	h.db.Where("role IN ?", []string{"coordinateur", "admin"}).
		Select("id, name, email, role, titre, organisation, is_online, zone, avatar, created_at").
		Find(&users)

	// For each coordinator, count active and resolved cases
	type CoordStats struct {
		models.User
		ActiveCases   int64 `json:"active_cases"`
		ResolvedCases int64 `json:"resolved_cases"`
	}

	result := make([]CoordStats, len(users))
	for i, u := range users {
		result[i].User = u
		h.db.Model(&models.Alert{}).Where("assigned_to = ? AND status != ?", u.ID, "resolved").Count(&result[i].ActiveCases)
		h.db.Model(&models.Alert{}).Where("assigned_to = ? AND status = ?", u.ID, "resolved").Count(&result[i].ResolvedCases)
	}

	jsonOK(w, result)
}

// PUT /team/:id/status — toggle online/offline
func (h *TeamHandler) UpdateStatus(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	var req struct {
		IsOnline bool `json:"is_online"`
	}
	decode(r, &req)
	h.db.Model(&models.User{}).Where("id = ?", id).Update("is_online", req.IsOnline)
	jsonOK(w, map[string]bool{"is_online": req.IsOnline})
}
