package database

import (
	"log/slog"
	"os"
	"strings"

	"github.com/glebarez/sqlite"
	"github.com/mara-app/backend/internal/models"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

func Connect(dsn string) *gorm.DB {
	var db *gorm.DB
	var err error

	cfg := &gorm.Config{Logger: logger.Default.LogMode(logger.Warn)}

	if strings.HasPrefix(dsn, "postgres") || strings.HasPrefix(dsn, "host=") {
		db, err = gorm.Open(postgres.Open(dsn), cfg)
	} else {
		db, err = gorm.Open(sqlite.Open(dsn), cfg)
	}

	if err != nil {
		slog.Error("database connection failed", "err", err)
		os.Exit(1)
	}

	Migrate(db)
	return db
}

func Migrate(db *gorm.DB) {
	// PostgreSQL: drop unique constraints with IF EXISTS to be idempotent on every deploy
	if db.Dialector.Name() == "postgres" {
		stmts := []string{
			`ALTER TABLE IF EXISTS users DROP CONSTRAINT IF EXISTS uni_users_email`,
			`ALTER TABLE IF EXISTS violence_types DROP CONSTRAINT IF EXISTS uni_violence_types_slug`,
			`ALTER TABLE IF EXISTS reports DROP CONSTRAINT IF EXISTS uni_reports_reference`,
			`ALTER TABLE IF EXISTS conversations DROP CONSTRAINT IF EXISTS uni_conversations_session_token`,
			`ALTER TABLE IF EXISTS relief_web_reports DROP CONSTRAINT IF EXISTS uni_relief_web_reports_ext_id`,
			`ALTER TABLE IF EXISTS alerts DROP CONSTRAINT IF EXISTS uni_alerts_reference`,
		}
		for _, s := range stmts {
			db.Exec(s)
		}
	}

	err := db.AutoMigrate(
		&models.User{},
		&models.ViolenceType{},
		&models.Report{},
		&models.ReportAttachment{},
		&models.Conversation{},
		&models.Message{},
		&models.Resource{},
		&models.ServiceDirectory{},
		&models.SosNumber{},
		&models.Announcement{},
		&models.ReliefWebReport{},
		&models.Alert{},
	)
	if err != nil {
		slog.Error("migration failed", "err", err)
		os.Exit(1)
	}
}

func Seed(db *gorm.DB) {
	seedViolenceTypes(db)
	seedSosNumbers(db)
	seedServices(db)
	seedAdminUser(db)
}

func seedViolenceTypes(db *gorm.DB) {
	var count int64
	db.Model(&models.ViolenceType{}).Count(&count)
	if count > 0 {
		return
	}
	types := []models.ViolenceType{
		{Slug: "physical", LabelFr: "Violence physique", Sub: "Coups, blessures, agression", Icon: "shield-alert", Color: "#B5103C"},
		{Slug: "sexual", LabelFr: "Violence sexuelle", Sub: "Agression, harcèlement sexuel", Icon: "shield", Color: "#7A3B8C"},
		{Slug: "verbal", LabelFr: "Violence verbale", Sub: "Menaces, insultes, intimidation", Icon: "message-circle", Color: "#B87A1A"},
		{Slug: "psych", LabelFr: "Violence psychologique", Sub: "Contrôle, humiliation, isolement", Icon: "brain", Color: "#1A2E4A"},
		{Slug: "domestic", LabelFr: "Violence domestique", Sub: "Au sein du foyer ou de la famille", Icon: "home", Color: "#C85A18"},
		{Slug: "neglect", LabelFr: "Négligence grave", Sub: "Abandon, privation de soins", Icon: "alert-circle", Color: "#2D6A4F"},
	}
	db.Create(&types)
}

func seedSosNumbers(db *gorm.DB) {
	var count int64
	db.Model(&models.SosNumber{}).Count(&count)
	if count > 0 {
		return
	}
	numbers := []models.SosNumber{
		{Label: "Police nationale", Number: "17", Icon: "shield", SortOrder: 1},
		{Label: "SAMU", Number: "15", Icon: "heart-pulse", SortOrder: 2},
		{Label: "Pompiers", Number: "18", Icon: "flame", SortOrder: 3},
		{Label: "Ligne Verte VBG", Number: "80000001", Icon: "phone", SortOrder: 4},
		{Label: "VeilleProtect USSD", Number: "*115#", Icon: "smartphone", SortOrder: 5},
	}
	db.Create(&numbers)
}

func seedServices(db *gorm.DB) {
	var count int64
	db.Model(&models.ServiceDirectory{}).Count(&count)
	if count > 0 {
		return
	}
	services := []models.ServiceDirectory{
		{Name: "Centre ESPOIR", Type: "refuge", Region: "Abidjan", Phone: "+225 07 00 01 01", Address: "Cocody", Lat: 5.3698, Lng: -3.9828},
		{Name: "Hôpital Général de Cocody", Type: "health", Region: "Abidjan", Phone: "+225 27 22 44 01", Address: "Cocody", Lat: 5.3600, Lng: -3.9700},
		{Name: "Commissariat Central Abobo", Type: "police", Region: "Abidjan", Phone: "17", Address: "Abobo", Lat: 5.4249, Lng: -4.0197},
		{Name: "ONG Femmes Debout", Type: "ngo", Region: "Abidjan", Phone: "+225 07 11 22 33", Address: "Yopougon", Lat: 5.3533, Lng: -4.0780},
	}
	db.Create(&services)
}

func seedAdminUser(db *gorm.DB) {
	var count int64
	db.Model(&models.User{}).Count(&count)
	if count > 0 {
		return
	}
	// Hash is bcrypt of "password"
	hash := "$2a$12$UIpYM.wjEoYhxtw7Pkc4q.LqnEAwyTmGs2cR81ns7wtxIEReX8NBq"
	users := []models.User{
		{Name: "Admin MARA", Email: "admin@mara.bf", Password: hash, Role: models.RoleAdmin, Titre: "Administrateur"},
		{Name: "Aminata Diallo", Email: "aminata@mara.bf", Password: hash, Role: models.RoleCoordinator, Titre: "Coordinatrice principale", Zone: "Cocody / Plateau", Avatar: "AD"},
		{Name: "Moussa Koné", Email: "moussa@mara.bf", Password: hash, Role: models.RoleCoordinator, Titre: "Coordinateur social", Zone: "Abobo / Adjamé", Avatar: "MK"},
		{Name: "Fatou Sanogo", Email: "fatou@mara.bf", Password: hash, Role: models.RoleCounselor, Titre: "Conseillère", Zone: "Yopougon", Avatar: "FS"},
	}
	db.Create(&users)
}
