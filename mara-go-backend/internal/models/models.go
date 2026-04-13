package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// ─── User ─────────────────────────────────────────────────────────────────────

type UserRole string

const (
	RoleAdmin        UserRole = "admin"
	RoleProfessional UserRole = "professionnel"
	RoleCounselor    UserRole = "conseiller"
	RoleCoordinator  UserRole = "coordinateur"
)

type User struct {
	ID           uint           `json:"id" gorm:"primaryKey"`
	Name         string         `json:"name" gorm:"not null"`
	Email        string         `json:"email" gorm:"uniqueIndex;not null"`
	Password     string         `json:"-" gorm:"not null"`
	Role         UserRole       `json:"role" gorm:"default:'conseiller'"`
	Titre        string         `json:"titre"`
	Specialite   string         `json:"specialite"`
	Organisation string         `json:"organisation"`
	IsOnline     bool           `json:"is_online" gorm:"default:false"`
	Zone         string         `json:"zone"`
	Avatar       string         `json:"avatar"`
	CreatedAt    time.Time      `json:"created_at"`
	UpdatedAt    time.Time      `json:"updated_at"`
	DeletedAt    gorm.DeletedAt `json:"-" gorm:"index"`
}

// ─── ViolenceType ─────────────────────────────────────────────────────────────

type ViolenceType struct {
	ID      uint   `json:"id" gorm:"primaryKey"`
	Slug    string `json:"slug" gorm:"uniqueIndex;not null"`
	LabelFr string `json:"label_fr" gorm:"not null"`
	Sub     string `json:"sub"`
	Icon    string `json:"icon"`
	Color   string `json:"color"`
}

// ─── Report ───────────────────────────────────────────────────────────────────

type ReportStatus string
type ReportPriority string
type ReporterType string

const (
	StatusNew        ReportStatus = "new"
	StatusAssigned   ReportStatus = "assigned"
	StatusInProgress ReportStatus = "inprogress"
	StatusResolved   ReportStatus = "resolved"
	StatusClosed     ReportStatus = "closed"

	PriorityCritical ReportPriority = "critical"
	PriorityHigh     ReportPriority = "high"
	PriorityMedium   ReportPriority = "medium"
	PriorityLow      ReportPriority = "low"

	ReporterAnonymous  ReporterType = "anonymous"
	ReporterPseudo     ReporterType = "pseudo"
	ReporterIdentified ReporterType = "identified"
)

type Report struct {
	ID           uint           `json:"id" gorm:"primaryKey"`
	Reference    string         `json:"reference" gorm:"uniqueIndex;not null"`
	ReporterType ReporterType   `json:"reporter_type" gorm:"default:'anonymous'"`
	VictimGender string         `json:"victim_gender"`
	Region       string         `json:"region"`
	Zone         string         `json:"zone"`
	Lat          float64        `json:"lat"`
	Lng          float64        `json:"lng"`
	Description  string         `json:"description"`
	Status       ReportStatus   `json:"status" gorm:"default:'new'"`
	Priority     ReportPriority `json:"priority" gorm:"default:'medium'"`
	IsOngoing    bool           `json:"is_ongoing" gorm:"default:false"`
	Channel      string         `json:"channel" gorm:"default:'app'"`
	HasPhoto     bool           `json:"has_photo" gorm:"default:false"`
	HasAudio     bool           `json:"has_audio" gorm:"default:false"`
	Notes        string         `json:"notes"`
	AssignedTo   *uint          `json:"assigned_to"`
	Coordinator  *User          `json:"coordinator,omitempty" gorm:"foreignKey:AssignedTo"`
	ViolenceTypes []ViolenceType `json:"violence_types" gorm:"many2many:report_violence_types"`
	Attachments  []ReportAttachment `json:"attachments,omitempty"`
	CreatedAt    time.Time      `json:"created_at"`
	UpdatedAt    time.Time      `json:"updated_at"`
	DeletedAt    gorm.DeletedAt `json:"-" gorm:"index"`
}

type ReportAttachment struct {
	ID        uint      `json:"id" gorm:"primaryKey"`
	ReportID  uint      `json:"report_id"`
	Type      string    `json:"type"`
	Path      string    `json:"path"`
	MimeType  string    `json:"mime_type"`
	Size      int64     `json:"size"`
	CreatedAt time.Time `json:"created_at"`
}

func (r *Report) BeforeCreate(tx *gorm.DB) error {
	if r.Reference == "" {
		r.Reference = generateReference()
	}
	return nil
}

func generateReference() string {
	id := uuid.New().String()
	return "MARA-" + time.Now().Format("2006") + "-" + id[:8]
}

// ─── Conversation ─────────────────────────────────────────────────────────────

type ConversationStatus string

const (
	ConvOpen   ConversationStatus = "open"
	ConvClosed ConversationStatus = "closed"
)

type Conversation struct {
	ID           uint               `json:"id" gorm:"primaryKey"`
	UserID       *uint              `json:"user_id"`
	ConseillerID *uint              `json:"conseiller_id"`
	SessionToken string             `json:"session_token" gorm:"uniqueIndex"`
	Status       ConversationStatus `json:"status" gorm:"default:'open'"`
	User         *User              `json:"user,omitempty" gorm:"foreignKey:UserID"`
	Conseiller   *User              `json:"conseiller,omitempty" gorm:"foreignKey:ConseillerID"`
	Messages     []Message          `json:"messages,omitempty"`
	CreatedAt    time.Time          `json:"created_at"`
	UpdatedAt    time.Time          `json:"updated_at"`
}

type Message struct {
	ID             uint      `json:"id" gorm:"primaryKey"`
	ConversationID uint      `json:"conversation_id"`
	SenderID       *uint     `json:"sender_id"`
	IsFromVisitor  bool      `json:"is_from_visitor" gorm:"default:false"`
	Body           string    `json:"body"`
	AudioPath      string    `json:"audio_path,omitempty"`
	AudioMime      string    `json:"audio_mime,omitempty"`
	CreatedAt      time.Time `json:"created_at"`
}

// ─── Resource ─────────────────────────────────────────────────────────────────

type Resource struct {
	ID          uint           `json:"id" gorm:"primaryKey"`
	Title       string         `json:"title" gorm:"not null"`
	Type        string         `json:"type"`
	Category    string         `json:"category"`
	URL         string         `json:"url"`
	Summary     string         `json:"summary"`
	IsPublished bool           `json:"is_published" gorm:"default:true"`
	CreatedAt   time.Time      `json:"created_at"`
	UpdatedAt   time.Time      `json:"updated_at"`
	DeletedAt   gorm.DeletedAt `json:"-" gorm:"index"`
}

// ─── ServiceDirectory ─────────────────────────────────────────────────────────

type ServiceDirectory struct {
	ID          uint   `json:"id" gorm:"primaryKey"`
	Name        string `json:"name" gorm:"not null"`
	Type        string `json:"type"`
	Region      string `json:"region"`
	Phone       string `json:"phone"`
	Address     string `json:"address"`
	Description string `json:"description"`
	Lat         float64 `json:"lat"`
	Lng         float64 `json:"lng"`
}

// ─── SosNumber ────────────────────────────────────────────────────────────────

type SosNumber struct {
	ID        uint   `json:"id" gorm:"primaryKey"`
	Label     string `json:"label" gorm:"not null"`
	Number    string `json:"number" gorm:"not null"`
	Icon      string `json:"icon"`
	SortOrder int    `json:"sort_order"`
}

// ─── Announcement ─────────────────────────────────────────────────────────────

type Announcement struct {
	ID        uint      `json:"id" gorm:"primaryKey"`
	Title     string    `json:"title"`
	Body      string    `json:"body"`
	IsActive  bool      `json:"is_active" gorm:"default:true"`
	SortOrder int       `json:"sort_order"`
	CreatedAt time.Time `json:"created_at"`
}

// ─── ReliefWebReport ──────────────────────────────────────────────────────────

type ReliefWebReport struct {
	ID          uint      `json:"id" gorm:"primaryKey"`
	ExtID       string    `json:"ext_id" gorm:"uniqueIndex"`
	Title       string    `json:"title"`
	Source      string    `json:"source"`
	URL         string    `json:"url"`
	PublishedAt time.Time `json:"published_at"`
	Country     string    `json:"country"`
	Theme       string    `json:"theme"`
	CreatedAt   time.Time `json:"created_at"`
}

// ─── Alert (VeilleProtect) ────────────────────────────────────────────────────

type Alert struct {
	ID          uint           `json:"id" gorm:"primaryKey"`
	Reference   string         `json:"reference" gorm:"uniqueIndex;not null"`
	TypeID      string         `json:"type_id"`
	VictimType  string         `json:"victim_type"`
	Severity    ReportPriority `json:"severity" gorm:"default:'medium'"`
	Status      ReportStatus   `json:"status" gorm:"default:'new'"`
	Lat         float64        `json:"lat"`
	Lng         float64        `json:"lng"`
	Zone        string         `json:"zone"`
	IsOngoing   bool           `json:"is_ongoing"`
	Channel     string         `json:"channel" gorm:"default:'app'"`
	IsAnonymous bool           `json:"is_anonymous" gorm:"default:true"`
	HasPhoto    bool           `json:"has_photo"`
	HasAudio    bool           `json:"has_audio"`
	Notes       string         `json:"notes"`
	AssignedTo  *uint          `json:"assigned_to"`
	Coordinator *User          `json:"coordinator,omitempty" gorm:"foreignKey:AssignedTo"`
	CreatedAt   time.Time      `json:"created_at"`
	UpdatedAt   time.Time      `json:"updated_at"`
}

func (a *Alert) BeforeCreate(tx *gorm.DB) error {
	if a.Reference == "" {
		id := uuid.New().String()
		a.Reference = "VLP-" + id[:4] + "-" + id[4:8]
	}
	return nil
}
