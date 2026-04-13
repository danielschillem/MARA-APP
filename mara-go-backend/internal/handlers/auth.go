package handlers

import (
	"net/http"

	"github.com/mara-app/backend/internal/middleware"
	"github.com/mara-app/backend/internal/models"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

type AuthHandler struct {
	db     *gorm.DB
	secret string
}

func NewAuthHandler(db *gorm.DB, secret string) *AuthHandler {
	return &AuthHandler{db: db, secret: secret}
}

func (h *AuthHandler) Register(w http.ResponseWriter, r *http.Request) {
	var req struct {
		Name     string `json:"name"`
		Email    string `json:"email"`
		Password string `json:"password"`
		Role     string `json:"role"`
	}
	if err := decode(r, &req); err != nil || req.Email == "" || req.Password == "" || req.Name == "" {
		jsonError(w, "name, email and password required", http.StatusBadRequest)
		return
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

	role := models.RoleCounselor
	if req.Role != "" {
		role = models.UserRole(req.Role)
	}

	user := models.User{
		Name:     req.Name,
		Email:    req.Email,
		Password: string(hash),
		Role:     role,
	}
	if err := h.db.Create(&user).Error; err != nil {
		jsonError(w, "email already used", http.StatusConflict)
		return
	}

	token, _ := middleware.GenerateToken(&user, h.secret)
	w.WriteHeader(http.StatusCreated)
	jsonOK(w, map[string]interface{}{"user": user, "token": token})
}

func (h *AuthHandler) Login(w http.ResponseWriter, r *http.Request) {
	var req struct {
		Email    string `json:"email"`
		Password string `json:"password"`
	}
	if err := decode(r, &req); err != nil {
		jsonError(w, "invalid body", http.StatusBadRequest)
		return
	}

	var user models.User
	if err := h.db.Where("email = ?", req.Email).First(&user).Error; err != nil {
		jsonError(w, "invalid credentials", http.StatusUnauthorized)
		return
	}

	if err := bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(req.Password)); err != nil {
		jsonError(w, "invalid credentials", http.StatusUnauthorized)
		return
	}

	token, _ := middleware.GenerateToken(&user, h.secret)
	jsonOK(w, map[string]interface{}{"user": user, "token": token})
}

func (h *AuthHandler) Logout(w http.ResponseWriter, r *http.Request) {
	jsonOK(w, map[string]string{"message": "logged out"})
}

func (h *AuthHandler) Me(w http.ResponseWriter, r *http.Request) {
	claims := middleware.ClaimsFromCtx(r)
	var user models.User
	if err := h.db.First(&user, claims.UserID).Error; err != nil {
		jsonError(w, "user not found", http.StatusNotFound)
		return
	}
	jsonOK(w, user)
}

func (h *AuthHandler) ChangePassword(w http.ResponseWriter, r *http.Request) {
	claims := middleware.ClaimsFromCtx(r)
	var req struct {
		CurrentPassword string `json:"current_password"`
		NewPassword     string `json:"new_password"`
	}
	if err := decode(r, &req); err != nil || req.CurrentPassword == "" || req.NewPassword == "" {
		jsonError(w, "current_password and new_password required", http.StatusBadRequest)
		return
	}
	if len(req.NewPassword) < 8 {
		jsonError(w, "new password must be at least 8 characters", http.StatusBadRequest)
		return
	}

	var user models.User
	h.db.First(&user, claims.UserID)
	if err := bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(req.CurrentPassword)); err != nil {
		jsonError(w, "current password is incorrect", http.StatusUnauthorized)
		return
	}

	hash, _ := bcrypt.GenerateFromPassword([]byte(req.NewPassword), 12)
	h.db.Model(&user).Update("password", string(hash))
	jsonOK(w, map[string]string{"message": "password updated"})
}
