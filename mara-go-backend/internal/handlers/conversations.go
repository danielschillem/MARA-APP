package handlers

import (
	"crypto/rand"
	"encoding/hex"
	"net/http"
	"strconv"

	"github.com/go-chi/chi/v5"
	"github.com/mara-app/backend/internal/middleware"
	"github.com/mara-app/backend/internal/models"
	ws "github.com/mara-app/backend/internal/websocket"
	"gorm.io/gorm"
)

type ConversationHandler struct {
	db  *gorm.DB
	hub *ws.Hub
}

func NewConversationHandler(db *gorm.DB, hub *ws.Hub) *ConversationHandler {
	return &ConversationHandler{db: db, hub: hub}
}

func generateToken() string {
	b := make([]byte, 16)
	rand.Read(b)
	return hex.EncodeToString(b)
}

func (h *ConversationHandler) StartAnonymous(w http.ResponseWriter, r *http.Request) {
	conv := models.Conversation{
		SessionToken: generateToken(),
		Status:       models.ConvOpen,
	}
	if err := h.db.Create(&conv).Error; err != nil {
		jsonError(w, "internal error", http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusCreated)
	jsonOK(w, conv)
}

func (h *ConversationHandler) Show(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	token := r.URL.Query().Get("token")
	var conv models.Conversation
	q := h.db.Preload("User").Preload("Conseiller")
	if token != "" {
		q = q.Where("id = ? AND session_token = ?", id, token)
	} else {
		q = q.Where("id = ?", id)
	}
	if err := q.First(&conv).Error; err != nil {
		jsonError(w, "not found", http.StatusNotFound)
		return
	}
	jsonOK(w, conv)
}

func (h *ConversationHandler) Messages(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	var messages []models.Message
	h.db.Where("conversation_id = ?", id).Order("created_at ASC").Find(&messages)
	jsonOK(w, messages)
}

func (h *ConversationHandler) SendMessage(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	var req struct {
		Body          string `json:"body"`
		IsFromVisitor bool   `json:"is_from_visitor"`
		Token         string `json:"token"`
	}
	if err := decode(r, &req); err != nil || req.Body == "" {
		jsonError(w, "body required", http.StatusBadRequest)
		return
	}

	// Verify conversation exists
	var conv models.Conversation
	if err := h.db.First(&conv, id).Error; err != nil {
		jsonError(w, "conversation not found", http.StatusNotFound)
		return
	}

	// If visitor: verify token
	if req.IsFromVisitor && conv.SessionToken != req.Token {
		jsonError(w, "invalid token", http.StatusForbidden)
		return
	}

	msg := models.Message{
		ConversationID: conv.ID,
		IsFromVisitor:  req.IsFromVisitor,
		Body:           req.Body,
	}
	// If authenticated sender
	if claims := middleware.ClaimsFromCtx(r); claims != nil && !req.IsFromVisitor {
		msg.SenderID = &claims.UserID
	}

	h.db.Create(&msg)

	// Broadcast to WS room for this conversation
	h.hub.BroadcastToRoom("conv:"+id, ws.Event{
		Type:    "new_message",
		Payload: msg,
	})
	h.hub.Broadcast(ws.Event{Type: "conversation_activity", Payload: map[string]interface{}{
		"conversation_id": conv.ID,
	}})

	w.WriteHeader(http.StatusCreated)
	jsonOK(w, msg)
}

func (h *ConversationHandler) Index(w http.ResponseWriter, r *http.Request) {
	q := h.db.Model(&models.Conversation{}).Preload("User").Preload("Conseiller")

	if status := r.URL.Query().Get("status"); status != "" {
		q = q.Where("status = ?", status)
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
	q.Count(&total)

	var convs []models.Conversation
	q.Order("updated_at DESC").Limit(perPage).Offset((page - 1) * perPage).Find(&convs)

	jsonOK(w, map[string]interface{}{
		"data":     convs,
		"total":    total,
		"page":     page,
		"per_page": perPage,
	})
}

func (h *ConversationHandler) Store(w http.ResponseWriter, r *http.Request) {
	claims := middleware.ClaimsFromCtx(r)
	conv := models.Conversation{
		UserID:       &claims.UserID,
		SessionToken: generateToken(),
		Status:       models.ConvOpen,
	}
	h.db.Create(&conv)
	w.WriteHeader(http.StatusCreated)
	jsonOK(w, conv)
}

func (h *ConversationHandler) Assign(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	claims := middleware.ClaimsFromCtx(r)
	h.db.Model(&models.Conversation{}).Where("id = ?", id).Update("conseiller_id", claims.UserID)
	var conv models.Conversation
	h.db.Preload("Conseiller").First(&conv, id)
	jsonOK(w, conv)
}

func (h *ConversationHandler) Close(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	h.db.Model(&models.Conversation{}).Where("id = ?", id).Update("status", models.ConvClosed)
	jsonOK(w, map[string]string{"message": "conversation closed"})
}
