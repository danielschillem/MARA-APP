package handlers

import (
	"net/http"
	"strconv"

	"github.com/go-chi/chi/v5"
	"github.com/mara-app/backend/internal/models"
	"gorm.io/gorm"
)

type ResourceHandler struct {
	db *gorm.DB
}

func NewResourceHandler(db *gorm.DB) *ResourceHandler {
	return &ResourceHandler{db: db}
}

func (h *ResourceHandler) Index(w http.ResponseWriter, r *http.Request) {
	q := h.db.Where("is_published = ?", true)
	if t := r.URL.Query().Get("type"); t != "" {
		q = q.Where("type = ?", t)
	}
	if cat := r.URL.Query().Get("category"); cat != "" {
		q = q.Where("category = ?", cat)
	}
	if search := r.URL.Query().Get("search"); search != "" {
		q = q.Where("title LIKE ? OR summary LIKE ?", "%"+search+"%", "%"+search+"%")
	}

	page, _ := strconv.Atoi(r.URL.Query().Get("page"))
	if page < 1 {
		page = 1
	}
	perPage, _ := strconv.Atoi(r.URL.Query().Get("per_page"))
	if perPage < 1 || perPage > 100 {
		perPage = 20
	}

	var total int64
	q.Model(&models.Resource{}).Count(&total)

	var resources []models.Resource
	q.Order("created_at DESC").Limit(perPage).Offset((page - 1) * perPage).Find(&resources)

	jsonOK(w, map[string]interface{}{
		"data":     resources,
		"total":    total,
		"page":     page,
		"per_page": perPage,
	})
}

func (h *ResourceHandler) Show(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	var resource models.Resource
	if err := h.db.Where("id = ? AND is_published = ?", id, true).First(&resource).Error; err != nil {
		jsonError(w, "not found", http.StatusNotFound)
		return
	}
	jsonOK(w, resource)
}

func (h *ResourceHandler) Store(w http.ResponseWriter, r *http.Request) {
	var resource models.Resource
	if err := decode(r, &resource); err != nil || resource.Title == "" {
		jsonError(w, "title required", http.StatusBadRequest)
		return
	}
	h.db.Create(&resource)
	w.WriteHeader(http.StatusCreated)
	jsonOK(w, resource)
}

func (h *ResourceHandler) Update(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	var resource models.Resource
	if err := h.db.First(&resource, id).Error; err != nil {
		jsonError(w, "not found", http.StatusNotFound)
		return
	}
	decode(r, &resource)
	h.db.Save(&resource)
	jsonOK(w, resource)
}

func (h *ResourceHandler) Destroy(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	h.db.Delete(&models.Resource{}, id)
	w.WriteHeader(http.StatusNoContent)
}
