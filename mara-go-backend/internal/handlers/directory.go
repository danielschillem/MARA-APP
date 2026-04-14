package handlers

import (
	"net/http"
	"strconv"

	"github.com/go-chi/chi/v5"
	"github.com/mara-app/backend/internal/models"
	"gorm.io/gorm"
)

type DirectoryHandler struct {
	db *gorm.DB
}

func NewDirectoryHandler(db *gorm.DB) *DirectoryHandler {
	return &DirectoryHandler{db: db}
}

func (h *DirectoryHandler) ViolenceTypes(w http.ResponseWriter, r *http.Request) {
	var types []models.ViolenceType
	h.db.Find(&types)
	jsonOK(w, types)
}

func (h *DirectoryHandler) SosNumbers(w http.ResponseWriter, r *http.Request) {
	var numbers []models.SosNumber
	h.db.Order("sort_order").Find(&numbers)
	jsonOK(w, numbers)
}

func (h *DirectoryHandler) Services(w http.ResponseWriter, r *http.Request) {
	q := h.db.Model(&models.ServiceDirectory{})
	if t := r.URL.Query().Get("type"); t != "" {
		q = q.Where("type = ?", t)
	}
	if region := r.URL.Query().Get("region"); region != "" {
		q = q.Where("region = ?", region)
	}
	if search := r.URL.Query().Get("search"); search != "" {
		q = q.Where("name LIKE ? OR description LIKE ?", "%"+search+"%", "%"+search+"%")
	}
	var services []models.ServiceDirectory
	q.Find(&services)
	jsonOK(w, services)
}

// ── Admin: ServiceDirectory CRUD ─────────────────────────────────────────────

// POST /api/admin/services
func (h *DirectoryHandler) ServiceStore(w http.ResponseWriter, r *http.Request) {
	var svc models.ServiceDirectory
	if err := decode(r, &svc); err != nil || svc.Name == "" {
		jsonError(w, "name required", http.StatusBadRequest)
		return
	}
	if err := h.db.Create(&svc).Error; err != nil {
		jsonError(w, "could not create service", http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusCreated)
	jsonOK(w, svc)
}

// PUT /api/admin/services/{id}
func (h *DirectoryHandler) ServiceUpdate(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	var svc models.ServiceDirectory
	if err := h.db.First(&svc, id).Error; err != nil {
		jsonError(w, "not found", http.StatusNotFound)
		return
	}
	if err := decode(r, &svc); err != nil {
		jsonError(w, "invalid body", http.StatusBadRequest)
		return
	}
	h.db.Save(&svc)
	jsonOK(w, svc)
}

// DELETE /api/admin/services/{id}
func (h *DirectoryHandler) ServiceDestroy(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	if err := h.db.Delete(&models.ServiceDirectory{}, id).Error; err != nil {
		jsonError(w, "not found", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// ── Admin: SosNumber CRUD ────────────────────────────────────────────────────

// POST /api/admin/sos-numbers
func (h *DirectoryHandler) SosStore(w http.ResponseWriter, r *http.Request) {
	var req struct {
		Label     string `json:"label"`
		Number    string `json:"number"`
		Icon      string `json:"icon"`
		SortOrder int    `json:"sort_order"`
	}
	if err := decode(r, &req); err != nil || req.Label == "" || req.Number == "" {
		jsonError(w, "label and number required", http.StatusBadRequest)
		return
	}
	sos := models.SosNumber{
		Label:     req.Label,
		Number:    req.Number,
		Icon:      req.Icon,
		SortOrder: req.SortOrder,
	}
	if err := h.db.Create(&sos).Error; err != nil {
		jsonError(w, "could not create SOS number", http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusCreated)
	jsonOK(w, sos)
}

// PUT /api/admin/sos-numbers/{id}
func (h *DirectoryHandler) SosUpdate(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	var sos models.SosNumber
	if err := h.db.First(&sos, id).Error; err != nil {
		jsonError(w, "not found", http.StatusNotFound)
		return
	}
	var req struct {
		Label     string `json:"label"`
		Number    string `json:"number"`
		Icon      string `json:"icon"`
		SortOrder *int   `json:"sort_order"`
	}
	if err := decode(r, &req); err != nil {
		jsonError(w, "invalid body", http.StatusBadRequest)
		return
	}
	if req.Label != "" {
		sos.Label = req.Label
	}
	if req.Number != "" {
		sos.Number = req.Number
	}
	if req.Icon != "" {
		sos.Icon = req.Icon
	}
	if req.SortOrder != nil {
		sos.SortOrder = *req.SortOrder
	}
	h.db.Save(&sos)
	jsonOK(w, sos)
}

// DELETE /api/admin/sos-numbers/{id}
func (h *DirectoryHandler) SosDestroy(w http.ResponseWriter, r *http.Request) {
	id, err := strconv.Atoi(chi.URLParam(r, "id"))
	if err != nil {
		jsonError(w, "invalid id", http.StatusBadRequest)
		return
	}
	if err := h.db.Delete(&models.SosNumber{}, id).Error; err != nil {
		jsonError(w, "not found", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
