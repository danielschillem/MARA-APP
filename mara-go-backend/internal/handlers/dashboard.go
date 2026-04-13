package handlers

import (
	"net/http"
	"time"

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
	today := time.Now().Truncate(24 * time.Hour)
	thisMonth := time.Now().AddDate(0, 0, -30)

	var totalReports, newReports, resolvedReports, openConvs int64
	h.db.Model(&models.Report{}).Count(&totalReports)
	h.db.Model(&models.Report{}).Where("status = ?", "new").Count(&newReports)
	h.db.Model(&models.Report{}).Where("status = ? AND created_at >= ?", "resolved", today).Count(&resolvedReports)
	h.db.Model(&models.Conversation{}).Where("status = ?", "open").Count(&openConvs)

	// Reports by violence type (last 30 days)
	type TypeCount struct {
		LabelFr string `json:"label"`
		Count   int64  `json:"count"`
	}
	var byType []TypeCount
	h.db.Table("report_violence_types").
		Select("violence_types.label_fr, count(*) as count").
		Joins("JOIN violence_types ON violence_types.id = report_violence_types.violence_type_id").
		Joins("JOIN reports ON reports.id = report_violence_types.report_id").
		Where("reports.created_at >= ?", thisMonth).
		Group("violence_types.label_fr").
		Order("count DESC").
		Scan(&byType)

	// Reports by region
	type RegionCount struct {
		Region string `json:"region"`
		Count  int64  `json:"count"`
	}
	var byRegion []RegionCount
	h.db.Model(&models.Report{}).
		Select("region, count(*) as count").
		Where("created_at >= ? AND region != ''", thisMonth).
		Group("region").
		Order("count DESC").
		Limit(10).
		Scan(&byRegion)

	// Reports by channel
	type ChannelCount struct {
		Channel string `json:"channel"`
		Count   int64  `json:"count"`
	}
	var byChannel []ChannelCount
	h.db.Model(&models.Report{}).
		Select("channel, count(*) as count").
		Where("created_at >= ?", thisMonth).
		Group("channel").
		Scan(&byChannel)

	jsonOK(w, map[string]interface{}{
		"total_reports":    totalReports,
		"new_reports":      newReports,
		"resolved_today":   resolvedReports,
		"open_conversations": openConvs,
		"by_violence_type": byType,
		"by_region":        byRegion,
		"by_channel":       byChannel,
	})
}
