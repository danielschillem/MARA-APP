package handlers

import (
	"net/http"
	"strconv"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/mara-app/backend/internal/middleware"
	"github.com/mara-app/backend/internal/models"
	ws "github.com/mara-app/backend/internal/websocket"
	"gorm.io/gorm"
)

type AlertHandler struct {
	db  *gorm.DB
	hub *ws.Hub
}

func NewAlertHandler(db *gorm.DB, hub *ws.Hub) *AlertHandler {
	return &AlertHandler{db: db, hub: hub}
}

// POST /alerts — create a new VeilleProtect alert (citizen app)
func (h *AlertHandler) Store(w http.ResponseWriter, r *http.Request) {
	var req struct {
		TypeID      string  `json:"type_id"`
		VictimType  string  `json:"victim_type"`
		Lat         float64 `json:"lat"`
		Lng         float64 `json:"lng"`
		Zone        string  `json:"zone"`
		IsOngoing   bool    `json:"is_ongoing"`
		Channel     string  `json:"channel"`
		IsAnonymous bool    `json:"is_anonymous"`
		HasPhoto    bool    `json:"has_photo"`
		HasAudio    bool    `json:"has_audio"`
		Notes       string  `json:"notes"`
	}
	if err := decode(r, &req); err != nil {
		jsonError(w, "invalid body", http.StatusBadRequest)
		return
	}

	severity := models.PriorityMedium
	if req.IsOngoing {
		severity = models.PriorityCritical
	}

	alert := models.Alert{
		TypeID:      req.TypeID,
		VictimType:  req.VictimType,
		Lat:         req.Lat,
		Lng:         req.Lng,
		Zone:        req.Zone,
		IsOngoing:   req.IsOngoing,
		Channel:     req.Channel,
		IsAnonymous: req.IsAnonymous,
		HasPhoto:    req.HasPhoto,
		HasAudio:    req.HasAudio,
		Notes:       req.Notes,
		Severity:    severity,
	}
	if alert.Channel == "" {
		alert.Channel = "app"
	}

	if err := h.db.Create(&alert).Error; err != nil {
		jsonError(w, "could not create alert", http.StatusInternalServerError)
		return
	}

	// Broadcast to coordinator dashboard
	h.hub.Broadcast(ws.Event{Type: "new_alert", Payload: alert})

	w.WriteHeader(http.StatusCreated)
	jsonOK(w, alert)
}

// GET /alerts — list alerts (coordinator, filtered)
func (h *AlertHandler) Index(w http.ResponseWriter, r *http.Request) {
	q := h.db.Preload("Coordinator")

	if status := r.URL.Query().Get("status"); status != "" {
		q = q.Where("status = ?", status)
	}
	if severity := r.URL.Query().Get("severity"); severity != "" {
		q = q.Where("severity = ?", severity)
	}
	if zone := r.URL.Query().Get("zone"); zone != "" {
		q = q.Where("zone = ?", zone)
	}

	page, _ := strconv.Atoi(r.URL.Query().Get("page"))
	if page < 1 {
		page = 1
	}
	limit := 50
	offset := (page - 1) * limit

	var total int64
	q.Model(&models.Alert{}).Count(&total)

	var alerts []models.Alert
	q.Limit(limit).Offset(offset).Order("created_at DESC").Find(&alerts)

	jsonOK(w, map[string]interface{}{
		"data":  alerts,
		"total": total,
		"page":  page,
	})
}

// GET /alerts/:id
func (h *AlertHandler) Show(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	var alert models.Alert
	if err := h.db.Preload("Coordinator").First(&alert, id).Error; err != nil {
		jsonError(w, "not found", http.StatusNotFound)
		return
	}
	jsonOK(w, alert)
}

// PUT /alerts/:id — update status, assign coordinator
func (h *AlertHandler) Update(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	var alert models.Alert
	if err := h.db.First(&alert, id).Error; err != nil {
		jsonError(w, "not found", http.StatusNotFound)
		return
	}

	var req struct {
		Status     string `json:"status"`
		Notes      string `json:"notes"`
		AssignedTo *uint  `json:"assigned_to"`
	}
	decode(r, &req)

	updates := map[string]interface{}{}
	if req.Status != "" {
		updates["status"] = req.Status
	}
	if req.Notes != "" {
		updates["notes"] = req.Notes
	}
	if req.AssignedTo != nil {
		updates["assigned_to"] = req.AssignedTo
		if req.Status == "" {
			updates["status"] = models.StatusAssigned
		}
	}

	h.db.Model(&alert).Updates(updates)
	h.db.Preload("Coordinator").First(&alert, id)

	h.hub.Broadcast(ws.Event{Type: "alert_updated", Payload: alert})
	jsonOK(w, alert)
}

// GET /alerts/dashboard — coordinator KPIs
func (h *AlertHandler) Dashboard(w http.ResponseWriter, r *http.Request) {
	var total, critical, resolved, newCount, inprogress int64
	today := time.Now().Truncate(24 * time.Hour)

	h.db.Model(&models.Alert{}).Where("created_at >= ?", today).Count(&total)
	h.db.Model(&models.Alert{}).Where("severity = ? AND status != ?", "critical", "resolved").Count(&critical)
	h.db.Model(&models.Alert{}).Where("status = ? AND created_at >= ?", "resolved", today).Count(&resolved)
	h.db.Model(&models.Alert{}).Where("status = ?", "new").Count(&newCount)
	h.db.Model(&models.Alert{}).Where("status = ?", "inprogress").Count(&inprogress)

	// Zones at risk
	type ZoneCount struct {
		Zone  string
		Count int64
	}
	var zones []ZoneCount
	h.db.Model(&models.Alert{}).
		Select("zone, count(*) as count").
		Where("status != ?", "resolved").
		Group("zone").
		Order("count DESC").
		Limit(5).
		Scan(&zones)

	// Active coordinators
	var activeCoords int64
	h.db.Model(&models.User{}).Where("role = ? AND is_online = ?", "coordinateur", true).Count(&activeCoords)

	jsonOK(w, map[string]interface{}{
		"today_total":        total,
		"critical_active":    critical,
		"resolved_today":     resolved,
		"new":                newCount,
		"in_progress":        inprogress,
		"top_zones":          zones,
		"active_coordinators": activeCoords,
	})
}

// GET /alerts/map — GeoJSON-like list for map rendering
func (h *AlertHandler) MapData(w http.ResponseWriter, r *http.Request) {
	var alerts []models.Alert
	h.db.Where("status != ?", "resolved").Select("id, reference, type_id, victim_type, severity, status, lat, lng, zone, is_ongoing, created_at").Find(&alerts)
	jsonOK(w, alerts)
}

func (h *AlertHandler) Assign(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	claims := middleware.ClaimsFromCtx(r)

	var alert models.Alert
	if err := h.db.First(&alert, id).Error; err != nil {
		jsonError(w, "not found", http.StatusNotFound)
		return
	}

	h.db.Model(&alert).Updates(map[string]interface{}{
		"assigned_to": claims.UserID,
		"status":      models.StatusAssigned,
	})
	h.db.Preload("Coordinator").First(&alert, id)

	h.hub.Broadcast(ws.Event{Type: "alert_assigned", Payload: alert})
	jsonOK(w, alert)
}
