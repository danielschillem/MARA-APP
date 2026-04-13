package handlers

import (
	"encoding/json"
	"fmt"
	"net/http"
	"strings"
	"time"

	"github.com/mara-app/backend/internal/models"
	"gorm.io/gorm"
)

type ObservatoryHandler struct {
	db           *gorm.DB
	reliefWebURL string
}

func NewObservatoryHandler(db *gorm.DB, reliefWebURL string) *ObservatoryHandler {
	return &ObservatoryHandler{db: db, reliefWebURL: reliefWebURL}
}

// GET /api/observatory/stats — statistiques locales MARA
func (h *ObservatoryHandler) Stats(w http.ResponseWriter, r *http.Request) {
	var totalReports, resolved, critical int64
	var byRegion []struct {
		Region string
		Count  int64
	}
	var byType []struct {
		LabelFr string
		Count   int64
	}
	var byMonth []struct {
		Month string
		Count int64
	}

	h.db.Model(&models.Report{}).Count(&totalReports)
	h.db.Model(&models.Report{}).Where("status = ?", "resolved").Count(&resolved)
	h.db.Model(&models.Report{}).Where("priority = ?", "critical").Count(&critical)

	h.db.Model(&models.Report{}).
		Select("region, count(*) as count").
		Group("region").
		Order("count DESC").
		Limit(10).
		Scan(&byRegion)

	h.db.Table("report_violence_types").
		Joins("JOIN violence_types vt ON vt.id = report_violence_types.violence_type_id").
		Select("vt.label_fr, count(*) as count").
		Group("vt.label_fr").
		Order("count DESC").
		Scan(&byType)

	// Monthly trend (last 6 months)
	h.db.Model(&models.Report{}).
		Select("strftime('%Y-%m', created_at) as month, count(*) as count").
		Where("created_at >= ?", time.Now().AddDate(0, -6, 0)).
		Group("month").
		Order("month ASC").
		Scan(&byMonth)

	resolutionRate := float64(0)
	if totalReports > 0 {
		resolutionRate = float64(resolved) / float64(totalReports) * 100
	}

	jsonOK(w, map[string]interface{}{
		"total_reports":   totalReports,
		"resolved":        resolved,
		"critical":        critical,
		"resolution_rate": fmt.Sprintf("%.1f", resolutionRate),
		"by_region":       byRegion,
		"by_type":         byType,
		"by_month":        byMonth,
	})
}

// GET /api/observatory/reliefweb — rapports ReliefWeb en cache + sync
func (h *ObservatoryHandler) ReliefWeb(w http.ResponseWriter, r *http.Request) {
	// Return cached reports from DB
	var reports []models.ReliefWebReport
	h.db.Order("published_at DESC").Limit(20).Find(&reports)

	// If DB is empty or stale (> 6h), sync in background
	var count int64
	h.db.Model(&models.ReliefWebReport{}).Count(&count)
	if count == 0 {
		go h.syncReliefWeb()
	}

	jsonOK(w, reports)
}

// GET /api/observatory/reliefweb/sync — force sync (admin only)
func (h *ObservatoryHandler) SyncReliefWeb(w http.ResponseWriter, r *http.Request) {
	go h.syncReliefWeb()
	jsonOK(w, map[string]string{"message": "sync started"})
}

func (h *ObservatoryHandler) syncReliefWeb() {
	url := h.reliefWebURL + `/reports?appname=mara-app&fields[include][]=title&fields[include][]=source&fields[include][]=url&fields[include][]=date.created&fields[include][]=country&fields[include][]=theme&filter[operator]=AND&filter[conditions][0][field]=country.iso3&filter[conditions][0][value]=BFA&filter[conditions][1][field]=theme.name&filter[conditions][1][value][]=Protection%20and%20Human%20Rights&filter[conditions][1][operator]=OR&sort[]=date.created:desc&limit=50`

	resp, err := http.Get(url) //nolint:noctx
	if err != nil {
		return
	}
	defer resp.Body.Close()

	var result struct {
		Data []struct {
			ID     int `json:"id"`
			Fields struct {
				Title   string                   `json:"title"`
				Source  []struct{ Name string }  `json:"source"`
				URL     string                   `json:"url"`
				Date    struct{ Created string } `json:"date"`
				Country []struct{ ISO3 string }  `json:"country"`
				Theme   []struct{ Name string }  `json:"theme"`
			} `json:"fields"`
		} `json:"data"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return
	}

	for _, item := range result.Data {
		extID := fmt.Sprintf("%d", item.ID)
		var existing models.ReliefWebReport
		if h.db.Where("ext_id = ?", extID).First(&existing).Error == nil {
			continue // already in DB
		}

		pub, _ := time.Parse(time.RFC3339, item.Fields.Date.Created)
		source := ""
		if len(item.Fields.Source) > 0 {
			source = item.Fields.Source[0].Name
		}
		theme := ""
		themes := make([]string, len(item.Fields.Theme))
		for i, t := range item.Fields.Theme {
			themes[i] = t.Name
		}
		theme = strings.Join(themes, ", ")

		h.db.Create(&models.ReliefWebReport{
			ExtID:       extID,
			Title:       item.Fields.Title,
			Source:      source,
			URL:         item.Fields.URL,
			PublishedAt: pub,
			Country:     "BFA",
			Theme:       theme,
		})
	}
}
