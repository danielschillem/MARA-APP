package handlers

import (
	"fmt"
	"net/http"
	"time"

	authmw "github.com/mara-app/backend/internal/middleware"
	"github.com/mara-app/backend/internal/models"
	"gorm.io/gorm"
)

type DashboardHandler struct {
	db *gorm.DB
}

func NewDashboardHandler(db *gorm.DB) *DashboardHandler {
	return &DashboardHandler{db: db}
}

func (h *DashboardHandler) Index(w http.ResponseWriter, r *http.Request) {
	claims, _ := r.Context().Value(authmw.UserKey).(*authmw.Claims)
	now := time.Now()

	// ── Simple counts ─────────────────────────────────────────────────────────
	var reportsTotal, reportsNew, reportsUrgent, reportsResolved int64
	h.db.Model(&models.Report{}).Count(&reportsTotal)
	h.db.Model(&models.Report{}).Where("status = ?", "new").Count(&reportsNew)
	h.db.Model(&models.Report{}).Where("priority = ?", "critical").Count(&reportsUrgent)
	h.db.Model(&models.Report{}).Where("status = ?", "resolved").Count(&reportsResolved)

	var convActive, convWaiting int64
	h.db.Model(&models.Conversation{}).
		Where("status = ? AND conseiller_id IS NOT NULL", string(models.ConvOpen)).Count(&convActive)
	h.db.Model(&models.Conversation{}).
		Where("status = ? AND conseiller_id IS NULL", string(models.ConvOpen)).Count(&convWaiting)

	var profOnline, resourcesCount int64
	h.db.Model(&models.User{}).
		Where("is_online = ? AND role IN ?", true, []string{"conseiller", "professionnel", "coordinateur"}).
		Count(&profOnline)
	h.db.Model(&models.Resource{}).Where("is_published = ?", true).Count(&resourcesCount)

	// ── By status ─────────────────────────────────────────────────────────────
	type KV struct {
		Key   string `json:"key"`
		Count int64  `json:"count"`
	}
	var byStatus []KV
	h.db.Model(&models.Report{}).
		Select("status as key, count(*) as count").
		Group("status").Scan(&byStatus)
	byStatusMap := make(map[string]int64)
	for _, v := range byStatus {
		byStatusMap[v.Key] = v.Count
	}

	// ── By priority ───────────────────────────────────────────────────────────
	var byPriority []KV
	h.db.Model(&models.Report{}).
		Select("priority as key, count(*) as count").
		Group("priority").Scan(&byPriority)
	byPriorityMap := make(map[string]int64)
	for _, v := range byPriority {
		byPriorityMap[v.Key] = v.Count
	}

	// ── By region (top 10) ────────────────────────────────────────────────────
	var byRegion []KV
	h.db.Model(&models.Report{}).
		Select("region as key, count(*) as count").
		Where("region != ''").Group("region").Order("count DESC").Limit(10).
		Scan(&byRegion)
	byRegionMap := make(map[string]int64)
	for _, v := range byRegion {
		byRegionMap[v.Key] = v.Count
	}

	// ── By violence type ──────────────────────────────────────────────────────
	var byViolence []KV
	h.db.Table("report_violence_types").
		Select("violence_types.label_fr as key, count(*) as count").
		Joins("JOIN violence_types ON violence_types.id = report_violence_types.violence_type_id").
		Group("violence_types.label_fr").Order("count DESC").
		Scan(&byViolence)
	byViolenceMap := make(map[string]int64)
	for _, v := range byViolence {
		byViolenceMap[v.Key] = v.Count
	}

	// ── By month (last 12 months) ─────────────────────────────────────────────
	type MonthKV struct {
		Month string `json:"month"`
		Count int64  `json:"count"`
	}
	var byMonth []MonthKV
	since := now.AddDate(-1, 0, 0)
	var monthExpr string
	if h.db.Dialector.Name() == "postgres" {
		monthExpr = "to_char(created_at, 'YYYY-MM')"
	} else {
		monthExpr = "strftime('%Y-%m', created_at)"
	}
	h.db.Model(&models.Report{}).
		Select(fmt.Sprintf("%s as month, count(*) as count", monthExpr)).
		Where("created_at >= ?", since).
		Group("month").Order("month ASC").
		Scan(&byMonth)
	byMonthMap := make(map[string]int64)
	for _, v := range byMonth {
		byMonthMap[v.Month] = v.Count
	}

	// ── Recent reports (last 10) ──────────────────────────────────────────────
	type ReportSummary struct {
		ID        uint      `json:"id"`
		Reference string    `json:"reference"`
		CreatedAt time.Time `json:"created_at"`
		Region    string    `json:"region"`
		Status    string    `json:"status"`
		Priority  string    `json:"priority"`
	}
	var recentReports []ReportSummary
	h.db.Model(&models.Report{}).
		Select("id, reference, created_at, region, status, priority").
		Order("created_at DESC").Limit(10).
		Scan(&recentReports)

	// ── My assigned reports ───────────────────────────────────────────────────
	var myAssigned []ReportSummary
	if claims != nil {
		h.db.Model(&models.Report{}).
			Select("id, reference, created_at, region, status, priority").
			Where("assigned_to = ? AND status NOT IN ?", claims.UserID, []string{"resolved", "closed"}).
			Order("created_at DESC").
			Scan(&myAssigned)
	}

	// ── Alert stats ───────────────────────────────────────────────────────────
	var alertsTotal, alertsNew, alertsCritical int64
	h.db.Model(&models.Alert{}).Count(&alertsTotal)
	h.db.Model(&models.Alert{}).Where("status = ?", "new").Count(&alertsNew)
	h.db.Model(&models.Alert{}).Where("severity = ? AND status != ?", "critical", "resolved").Count(&alertsCritical)

	jsonOK(w, map[string]interface{}{
		"reports_total":            reportsTotal,
		"reports_new":              reportsNew,
		"reports_urgent":           reportsUrgent,
		"reports_resolved":         reportsResolved,
		"conversations_active":     convActive,
		"conversations_waiting":    convWaiting,
		"professionals_online":     profOnline,
		"alerts_total":             alertsTotal,
		"alerts_new":               alertsNew,
		"alerts_critical":          alertsCritical,
		"reports_by_status":        byStatusMap,
		"reports_by_region":        byRegionMap,
		"reports_by_priority":      byPriorityMap,
		"reports_by_month":         byMonthMap,
		"reports_by_violence_type": byViolenceMap,
		"recent_reports":           recentReports,
		"resources_count":          resourcesCount,
		"my_assigned":              myAssigned,
	})
}
