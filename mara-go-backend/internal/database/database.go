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
	isPostgres := db.Dialector.Name() == "postgres"

	// ── Step 1: pre-clean any stale unique indexes / constraints left by previous
	// failed deployments. Uses IF EXISTS so it is always safe to run.
	if isPostgres {
		cleanups := []string{
			// Drop as constraint (ALTER TABLE ... DROP CONSTRAINT)
			`ALTER TABLE IF EXISTS users              DROP CONSTRAINT IF EXISTS uni_users_email`,
			`ALTER TABLE IF EXISTS violence_types     DROP CONSTRAINT IF EXISTS uni_violence_types_slug`,
			`ALTER TABLE IF EXISTS reports            DROP CONSTRAINT IF EXISTS uni_reports_reference`,
			`ALTER TABLE IF EXISTS conversations      DROP CONSTRAINT IF EXISTS uni_conversations_session_token`,
			`ALTER TABLE IF EXISTS relief_web_reports DROP CONSTRAINT IF EXISTS uni_relief_web_reports_ext_id`,
			`ALTER TABLE IF EXISTS alerts             DROP CONSTRAINT IF EXISTS uni_alerts_reference`,
			// Drop as index (CREATE UNIQUE INDEX leaves an index, not a named constraint)
			`DROP INDEX IF EXISTS uni_users_email`,
			`DROP INDEX IF EXISTS uni_violence_types_slug`,
			`DROP INDEX IF EXISTS uni_reports_reference`,
			`DROP INDEX IF EXISTS uni_conversations_session_token`,
			`DROP INDEX IF EXISTS uni_relief_web_reports_ext_id`,
			`DROP INDEX IF EXISTS uni_alerts_reference`,
			`DROP INDEX IF EXISTS idx_users_email`,
			`DROP INDEX IF EXISTS idx_violence_types_slug`,
			`DROP INDEX IF EXISTS idx_reports_reference`,
			`DROP INDEX IF EXISTS idx_conversations_session_token`,
			`DROP INDEX IF EXISTS idx_relief_web_reports_ext_id`,
			`DROP INDEX IF EXISTS idx_alerts_reference`,
		}
		for _, sql := range cleanups {
			db.Exec(sql) // errors are intentionally ignored (IF EXISTS handles them)
		}
	}

	// ── Step 2: migrate each model separately so one failure cannot block others.
	// GORM creates the table (CREATE TABLE IF NOT EXISTS) before managing indexes,
	// so even if index reconciliation fails the table will exist.
	allModels := []interface{}{
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
	}
	for _, m := range allModels {
		if err := db.AutoMigrate(m); err != nil {
			// Non-fatal: GORM may warn about constraint reconciliation on PostgreSQL.
			// Unique constraints are enforced by the manual indexes created below.
			slog.Warn("migrate: non-fatal schema warning", "err", err)
		}
	}

	// ── Step 3: create unique indexes with IF NOT EXISTS — fully idempotent on
	// both SQLite and PostgreSQL. This is the authoritative source of uniqueness.
	uniqueIdxs := []string{
		`CREATE UNIQUE INDEX IF NOT EXISTS idx_users_email                   ON users(email)`,
		`CREATE UNIQUE INDEX IF NOT EXISTS idx_violence_types_slug           ON violence_types(slug)`,
		`CREATE UNIQUE INDEX IF NOT EXISTS idx_reports_reference             ON reports(reference)`,
		`CREATE UNIQUE INDEX IF NOT EXISTS idx_conversations_session_token   ON conversations(session_token)`,
		`CREATE UNIQUE INDEX IF NOT EXISTS idx_relief_web_reports_ext_id     ON relief_web_reports(ext_id)`,
		`CREATE UNIQUE INDEX IF NOT EXISTS idx_alerts_reference              ON alerts(reference)`,
	}
	for _, idx := range uniqueIdxs {
		if err := db.Exec(idx).Error; err != nil {
			slog.Warn("unique index: already exists or non-fatal", "err", err)
		}
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
