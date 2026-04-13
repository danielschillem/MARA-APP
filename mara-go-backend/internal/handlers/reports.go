package handlers

import (
	"encoding/csv"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/mara-app/backend/internal/models"
	ws "github.com/mara-app/backend/internal/websocket"
	"gorm.io/gorm"
)

type ReportHandler struct {
	db        *gorm.DB
	hub       *ws.Hub
	uploadDir string
	maxUpload int64
}

func NewReportHandler(db *gorm.DB, hub *ws.Hub) *ReportHandler {
	dir := "uploads/reports"
	os.MkdirAll(dir, 0755)
	return &ReportHandler{db: db, hub: hub, uploadDir: dir, maxUpload: 20 << 20} // 20 MB
}

var allowedMimes = map[string]string{
	"image/jpeg":      ".jpg",
	"image/png":       ".png",
	"image/webp":      ".webp",
	"audio/webm":      ".webm",
	"audio/mp4":       ".mp4",
	"audio/mpeg":      ".mp3",
	"application/pdf": ".pdf",
}

func (h *ReportHandler) Store(w http.ResponseWriter, r *http.Request) {
	// Support both JSON and multipart
	var (
		reporterType  string
		victimGender  string
		region        string
		zone          string
		lat, lng      float64
		description   string
		isOngoing     bool
		channel       string
		violenceTypes []string
	)

	ct := r.Header.Get("Content-Type")
	if strings.HasPrefix(ct, "multipart/form-data") {
		r.ParseMultipartForm(h.maxUpload)
		reporterType = r.FormValue("reporter_type")
		victimGender = r.FormValue("victim_gender")
		region = r.FormValue("region")
		zone = r.FormValue("zone")
		lat, _ = strconv.ParseFloat(r.FormValue("lat"), 64)
		lng, _ = strconv.ParseFloat(r.FormValue("lng"), 64)
		description = r.FormValue("description")
		isOngoing = r.FormValue("is_ongoing") == "true"
		channel = r.FormValue("channel")
		violenceTypes = r.Form["violence_types[]"]
		if len(violenceTypes) == 0 {
			violenceTypes = r.Form["violence_types"]
		}
	} else {
		var req struct {
			ReporterType  string   `json:"reporter_type"`
			VictimGender  string   `json:"victim_gender"`
			Region        string   `json:"region"`
			Zone          string   `json:"zone"`
			Lat           float64  `json:"lat"`
			Lng           float64  `json:"lng"`
			Description   string   `json:"description"`
			IsOngoing     bool     `json:"is_ongoing"`
			Channel       string   `json:"channel"`
			ViolenceTypes []string `json:"violence_types"`
		}
		if err := decode(r, &req); err != nil {
			jsonError(w, "invalid body", http.StatusBadRequest)
			return
		}
		reporterType = req.ReporterType
		victimGender = req.VictimGender
		region = req.Region
		zone = req.Zone
		lat = req.Lat
		lng = req.Lng
		description = req.Description
		isOngoing = req.IsOngoing
		channel = req.Channel
		violenceTypes = req.ViolenceTypes
	}

	priority := models.PriorityMedium
	if isOngoing {
		priority = models.PriorityHigh
	}

	report := models.Report{
		ReporterType: models.ReporterType(reporterType),
		VictimGender: victimGender,
		Region:       region,
		Zone:         zone,
		Lat:          lat,
		Lng:          lng,
		Description:  description,
		IsOngoing:    isOngoing,
		Channel:      channel,
		Priority:     priority,
	}
	if report.ReporterType == "" {
		report.ReporterType = models.ReporterAnonymous
	}
	if report.Channel == "" {
		report.Channel = "app"
	}

	if err := h.db.Create(&report).Error; err != nil {
		jsonError(w, "could not create report", http.StatusInternalServerError)
		return
	}

	// Attach violence types
	if len(violenceTypes) > 0 {
		var vTypes []models.ViolenceType
		h.db.Where("slug IN ?", violenceTypes).Find(&vTypes)
		h.db.Model(&report).Association("ViolenceTypes").Replace(vTypes)
	}

	// Handle file uploads (multipart only)
	if strings.HasPrefix(ct, "multipart/form-data") && r.MultipartForm != nil {
		for _, files := range r.MultipartForm.File {
			for _, fh := range files {
				ext, ok := allowedMimes[fh.Header.Get("Content-Type")]
				if !ok {
					continue // skip unknown MIME
				}
				if fh.Size > h.maxUpload {
					continue // skip oversized file
				}
				src, err := fh.Open()
				if err != nil {
					continue
				}
				filename := uuid.New().String() + ext
				destPath := filepath.Join(h.uploadDir, filename)
				dst, err := os.Create(destPath)
				if err != nil {
					src.Close()
					continue
				}
				io.Copy(dst, src)
				src.Close()
				dst.Close()

				mime := fh.Header.Get("Content-Type")
				fileType := "photo"
				if strings.HasPrefix(mime, "audio/") {
					fileType = "audio"
				} else if mime == "application/pdf" {
					fileType = "document"
				}

				attach := models.ReportAttachment{
					ReportID: report.ID,
					Type:     fileType,
					Path:     destPath,
					MimeType: mime,
					Size:     fh.Size,
				}
				h.db.Create(&attach)

				if fileType == "photo" {
					h.db.Model(&report).Update("has_photo", true)
				} else if fileType == "audio" {
					h.db.Model(&report).Update("has_audio", true)
				}
			}
		}
	}

	h.db.Preload("ViolenceTypes").Preload("Attachments").First(&report, report.ID)

	// Broadcast new report event via WebSocket
	h.hub.Broadcast(ws.Event{Type: "new_report", Payload: report})

	w.WriteHeader(http.StatusCreated)
	jsonOK(w, report)
}

func (h *ReportHandler) Track(w http.ResponseWriter, r *http.Request) {
	ref := chi.URLParam(r, "reference")
	var report models.Report
	if err := h.db.Preload("ViolenceTypes").Where("reference = ?", ref).First(&report).Error; err != nil {
		jsonError(w, "report not found", http.StatusNotFound)
		return
	}
	jsonOK(w, report)
}

func (h *ReportHandler) Index(w http.ResponseWriter, r *http.Request) {
	q := h.db.Preload("ViolenceTypes").Preload("Coordinator")

	if status := r.URL.Query().Get("status"); status != "" {
		q = q.Where("status = ?", status)
	}
	if region := r.URL.Query().Get("region"); region != "" {
		q = q.Where("region = ?", region)
	}
	if priority := r.URL.Query().Get("priority"); priority != "" {
		q = q.Where("priority = ?", priority)
	}

	page, _ := strconv.Atoi(r.URL.Query().Get("page"))
	if page < 1 {
		page = 1
	}
	limit := 20
	offset := (page - 1) * limit

	var total int64
	q.Model(&models.Report{}).Count(&total)

	var reports []models.Report
	q.Limit(limit).Offset(offset).Order("created_at DESC").Find(&reports)

	jsonOK(w, map[string]interface{}{
		"data":  reports,
		"total": total,
		"page":  page,
	})
}

func (h *ReportHandler) Show(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	var report models.Report
	if err := h.db.Preload("ViolenceTypes").Preload("Coordinator").Preload("Attachments").First(&report, id).Error; err != nil {
		jsonError(w, "not found", http.StatusNotFound)
		return
	}
	jsonOK(w, report)
}

func (h *ReportHandler) Update(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	var report models.Report
	if err := h.db.First(&report, id).Error; err != nil {
		jsonError(w, "not found", http.StatusNotFound)
		return
	}

	var req struct {
		Status     string `json:"status"`
		Priority   string `json:"priority"`
		Notes      string `json:"notes"`
		AssignedTo *uint  `json:"assigned_to"`
	}
	decode(r, &req)

	updates := map[string]interface{}{}
	if req.Status != "" {
		updates["status"] = req.Status
	}
	if req.Priority != "" {
		updates["priority"] = req.Priority
	}
	if req.Notes != "" {
		updates["notes"] = req.Notes
	}
	if req.AssignedTo != nil {
		updates["assigned_to"] = req.AssignedTo
		updates["status"] = models.StatusAssigned
	}

	h.db.Model(&report).Updates(updates)
	h.db.Preload("ViolenceTypes").Preload("Coordinator").First(&report, id)

	h.hub.Broadcast(ws.Event{Type: "report_updated", Payload: report})
	jsonOK(w, report)
}

func (h *ReportHandler) Stats(w http.ResponseWriter, r *http.Request) {
	var total, newCount, inprogress, resolved int64
	h.db.Model(&models.Report{}).Count(&total)
	h.db.Model(&models.Report{}).Where("status = ?", "new").Count(&newCount)
	h.db.Model(&models.Report{}).Where("status = ?", "inprogress").Count(&inprogress)
	h.db.Model(&models.Report{}).Where("status = ?", "resolved").Count(&resolved)

	jsonOK(w, map[string]interface{}{
		"total":       total,
		"new":         newCount,
		"in_progress": inprogress,
		"resolved":    resolved,
	})
}

// GET /reports/export â€” export reports as CSV (protected)
func (h *ReportHandler) Export(w http.ResponseWriter, r *http.Request) {
	var reports []models.Report
	q := h.db.Preload("ViolenceTypes").Order("created_at DESC")

	if status := r.URL.Query().Get("status"); status != "" {
		q = q.Where("status = ?", status)
	}
	if region := r.URL.Query().Get("region"); region != "" {
		q = q.Where("region = ?", region)
	}
	q.Limit(5000).Find(&reports)

	w.Header().Set("Content-Type", "text/csv; charset=utf-8")
	w.Header().Set("Content-Disposition", fmt.Sprintf("attachment; filename=rapports-mara-%s.csv", time.Now().Format("2006-01-02")))

	wr := csv.NewWriter(w)
	defer wr.Flush()

	wr.Write([]string{"RÃ©fÃ©rence", "Date", "Type signalant", "Genre victime", "RÃ©gion", "Zone", "Statut", "PrioritÃ©", "Canal", "En cours", "Description", "Types de violence"})

	for _, rep := range reports {
		slugs := make([]string, len(rep.ViolenceTypes))
		for i, vt := range rep.ViolenceTypes {
			slugs[i] = vt.LabelFr
		}
		wr.Write([]string{
			rep.Reference,
			rep.CreatedAt.Format("02/01/2006 15:04"),
			string(rep.ReporterType),
			rep.VictimGender,
			rep.Region,
			rep.Zone,
			string(rep.Status),
			string(rep.Priority),
			rep.Channel,
			fmt.Sprintf("%v", rep.IsOngoing),
			rep.Description,
			strings.Join(slugs, " | "),
		})
	}
}

