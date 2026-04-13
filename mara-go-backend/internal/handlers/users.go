package handlers

import (
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/mara-app/backend/internal/models"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

type UserHandler struct {
	db *gorm.DB
}

func NewUserHandler(db *gorm.DB) *UserHandler {
	return &UserHandler{db: db}
}

// GET /admin/users
func (h *UserHandler) Index(w http.ResponseWriter, r *http.Request) {
	var users []models.User
	q := h.db.Unscoped()
	if role := r.URL.Query().Get("role"); role != "" {
		q = q.Where("role = ?", role)
	}
	if search := r.URL.Query().Get("search"); search != "" {
		like := "%" + search + "%"
		q = q.Where("name LIKE ? OR email LIKE ?", like, like)
	}
	q.Order("created_at DESC").Find(&users)
	jsonOK(w, users)
}

// POST /admin/users
func (h *UserHandler) Store(w http.ResponseWriter, r *http.Request) {
	var req struct {
		Name         string `json:"name"`
		Email        string `json:"email"`
		Password     string `json:"password"`
		Role         string `json:"role"`
		Titre        string `json:"titre"`
		Specialite   string `json:"specialite"`
		Organisation string `json:"organisation"`
		Zone         string `json:"zone"`
	}
	if err := decode(r, &req); err != nil || req.Email == "" || req.Name == "" {
		jsonError(w, "name and email required", http.StatusBadRequest)
		return
	}
	if req.Password == "" {
		req.Password = "Password1!" // default, user must reset
	}
	if len(req.Password) < 8 {
		jsonError(w, "password must be at least 8 characters", http.StatusBadRequest)
		return
	}

	hash, err := bcrypt.GenerateFromPassword([]byte(req.Password), 12)
	if err != nil {
		jsonError(w, "internal error", http.StatusInternalServerError)
		return
	}

	user := models.User{
		Name:         req.Name,
		Email:        req.Email,
		Password:     string(hash),
		Role:         models.UserRole(req.Role),
		Titre:        req.Titre,
		Specialite:   req.Specialite,
		Organisation: req.Organisation,
		Zone:         req.Zone,
	}
	if user.Role == "" {
		user.Role = models.RoleCounselor
	}

	if err := h.db.Create(&user).Error; err != nil {
		jsonError(w, "email already used", http.StatusConflict)
		return
	}
	w.WriteHeader(http.StatusCreated)
	jsonOK(w, user)
}

// PUT /admin/users/:id
func (h *UserHandler) Update(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	var user models.User
	if err := h.db.First(&user, id).Error; err != nil {
		jsonError(w, "not found", http.StatusNotFound)
		return
	}

	var req struct {
		Name         string `json:"name"`
		Role         string `json:"role"`
		Titre        string `json:"titre"`
		Specialite   string `json:"specialite"`
		Organisation string `json:"organisation"`
		Zone         string `json:"zone"`
		IsOnline     *bool  `json:"is_online"`
	}
	decode(r, &req)

	updates := map[string]interface{}{}
	if req.Name != "" {
		updates["name"] = req.Name
	}
	if req.Role != "" {
		updates["role"] = req.Role
	}
	if req.Titre != "" {
		updates["titre"] = req.Titre
	}
	if req.Specialite != "" {
		updates["specialite"] = req.Specialite
	}
	if req.Organisation != "" {
		updates["organisation"] = req.Organisation
	}
	if req.Zone != "" {
		updates["zone"] = req.Zone
	}
	if req.IsOnline != nil {
		updates["is_online"] = *req.IsOnline
	}

	h.db.Model(&user).Updates(updates)
	h.db.First(&user, id)
	jsonOK(w, user)
}

// DELETE /admin/users/:id — soft delete
func (h *UserHandler) Destroy(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	var user models.User
	if err := h.db.First(&user, id).Error; err != nil {
		jsonError(w, "not found", http.StatusNotFound)
		return
	}
	h.db.Delete(&user)
	jsonOK(w, map[string]string{"message": "user deleted"})
}
