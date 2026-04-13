package handlers

import (
	"net/http"

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
