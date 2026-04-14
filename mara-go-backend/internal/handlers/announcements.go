package handlers

import (
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/mara-app/backend/internal/models"
	"gorm.io/gorm"
)

type AnnouncementHandler struct {
	db *gorm.DB
}

func NewAnnouncementHandler(db *gorm.DB) *AnnouncementHandler {
	return &AnnouncementHandler{db: db}
}

// GET /api/announcements — public, only active ones
func (h *AnnouncementHandler) Index(w http.ResponseWriter, r *http.Request) {
	var announcements []models.Announcement
	h.db.Where("is_active = ?", true).
		Order("sort_order ASC, created_at DESC").
		Find(&announcements)
	jsonOK(w, announcements)
}

// GET /api/admin/announcements — admin, all
func (h *AnnouncementHandler) AdminIndex(w http.ResponseWriter, r *http.Request) {
	var announcements []models.Announcement
	h.db.Order("sort_order ASC, created_at DESC").Find(&announcements)
	jsonOK(w, announcements)
}

// POST /api/admin/announcements
func (h *AnnouncementHandler) Store(w http.ResponseWriter, r *http.Request) {
	var req struct {
		Title     string `json:"title"`
		Body      string `json:"body"`
		IsActive  bool   `json:"is_active"`
		SortOrder int    `json:"sort_order"`
	}
	if err := decode(r, &req); err != nil || req.Title == "" {
		jsonError(w, "title required", http.StatusBadRequest)
		return
	}
	ann := models.Announcement{
		Title:     req.Title,
		Body:      req.Body,
		IsActive:  req.IsActive,
		SortOrder: req.SortOrder,
	}
	if err := h.db.Create(&ann).Error; err != nil {
		jsonError(w, "could not create announcement", http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusCreated)
	jsonOK(w, ann)
}

// PUT /api/admin/announcements/{id}
func (h *AnnouncementHandler) Update(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	var ann models.Announcement
	if err := h.db.First(&ann, id).Error; err != nil {
		jsonError(w, "not found", http.StatusNotFound)
		return
	}
	var req struct {
		Title     string `json:"title"`
		Body      string `json:"body"`
		IsActive  *bool  `json:"is_active"`
		SortOrder *int   `json:"sort_order"`
	}
	if err := decode(r, &req); err != nil {
		jsonError(w, "invalid body", http.StatusBadRequest)
		return
	}
	if req.Title != "" {
		ann.Title = req.Title
	}
	if req.Body != "" {
		ann.Body = req.Body
	}
	if req.IsActive != nil {
		ann.IsActive = *req.IsActive
	}
	if req.SortOrder != nil {
		ann.SortOrder = *req.SortOrder
	}
	h.db.Save(&ann)
	jsonOK(w, ann)
}

// DELETE /api/admin/announcements/{id}
func (h *AnnouncementHandler) Destroy(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	if err := h.db.Delete(&models.Announcement{}, id).Error; err != nil {
		jsonError(w, "not found", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
