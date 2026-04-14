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
	seedResources(db)
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
		// Centre (Ouagadougou)
		{Name: "Police Nationale — Commissariat Central", Type: "securite", Region: "Centre", Phone: "17", Address: "Avenue de l'Indépendance, Ouagadougou", Description: "Commissariat central de Ouagadougou, disponible 24h/24", Lat: 12.3647, Lng: -1.5330},
		{Name: "SAMU Burkina Faso", Type: "urgence", Region: "Centre", Phone: "15", Address: "CHU Yalgado Ouédraogo, Ouagadougou", Description: "Service d'aide médicale urgente", Lat: 12.3620, Lng: -1.5202},
		{Name: "Association Voix de Femmes", Type: "ong", Region: "Centre", Phone: "+226 25 33 44 55", Address: "Secteur 15, Ouagadougou", Description: "Association de defense des droits des femmes", Lat: 12.3575, Lng: -1.5415},
		{Name: "CHU Yalgado Ouédraogo", Type: "medical", Region: "Centre", Phone: "+226 25 30 66 44", Address: "Avenue de l'Oubritenga, Ouagadougou", Description: "Centre hospitalier universitaire principal", Lat: 12.3621, Lng: -1.5201},
		{Name: "Ministère de la Femme et de la Solidarité", Type: "institutionnel", Region: "Centre", Phone: "+226 25 32 74 44", Address: "Avenue de l'Indépendance, Ouagadougou", Description: "Direction des affaires sociales et de la protection de la femme", Lat: 12.3680, Lng: -1.5280},
		{Name: "Barreau du Burkina Faso", Type: "juridique", Region: "Centre", Phone: "+226 25 30 67 37", Address: "Avenue de la Nation, Ouagadougou", Description: "Aide juridictionnelle et assistance aux victimes", Lat: 12.3655, Lng: -1.5260},
		// Hauts-Bassins (Bobo-Dioulasso)
		{Name: "Commissariat Régional Hauts-Bassins", Type: "securite", Region: "Hauts-Bassins", Phone: "17", Address: "Bobo-Dioulasso", Description: "Police nationale regional Hauts-Bassins", Lat: 11.1771, Lng: -4.2979},
		{Name: "CHR Souro Sanou Bobo", Type: "medical", Region: "Hauts-Bassins", Phone: "+226 20 97 00 27", Address: "Boulevard de la Résistance, Bobo-Dioulasso", Description: "Centre hospitalier régional de Bobo-Dioulasso", Lat: 11.1750, Lng: -4.2965},
		{Name: "Association AVVS Bobo", Type: "ong", Region: "Hauts-Bassins", Phone: "+226 20 97 11 22", Address: "Secteur 3, Bobo-Dioulasso", Description: "Aide aux victimes de violences sexuelles", Lat: 11.1800, Lng: -4.3010},
		// Centre-Nord
		{Name: "Direction Régionale de la Femme — Centre-Nord", Type: "institutionnel", Region: "Centre-Nord", Phone: "+226 40 45 00 11", Address: "Kaya", Description: "Service de protection de la femme et de l'enfant", Lat: 13.0939, Lng: -1.0867},
		// Nord
		{Name: "Commissariat Provinciale — Loroum", Type: "securite", Region: "Nord", Phone: "17", Address: "Titao", Description: "Police nationale provinciale du Loroum", Lat: 13.7694, Lng: -2.0760},
		// Est
		{Name: "CHR de Fada N'Gourma", Type: "medical", Region: "Est", Phone: "+226 40 77 00 24", Address: "Fada N'Gourma", Description: "Centre hospitalier régional de l'Est", Lat: 12.0583, Lng: 0.3463},
	}
	db.Create(&services)
}

func seedResources(db *gorm.DB) {
	var count int64
	db.Model(&models.Resource{}).Count(&count)
	if count > 0 {
		return
	}
	resources := []models.Resource{
		{
			Title:       "Comprendre la violence basée sur le genre au Burkina Faso",
			Type:        "article",
			Category:    "Sensibilisation",
			Summary:     "Un guide complet sur les différentes formes de violence et les mécanismes de protection existants au Burkina Faso.",
			IsPublished: true,
		},
		{
			Title:       "Loi N° 061-2015/CNT portant prévention, répression et réparation des VBG",
			Type:        "loi",
			Category:    "Textes légaux",
			Summary:     "La loi burkinabè qui définit et sanctionne les violences basées sur le genre. Obligations des services publics.",
			URL:         "https://faolex.fao.org/docs/pdf/bkf153272.pdf",
			IsPublished: true,
		},
		{
			Title:       "Guide pratique : que faire si vous êtes victime de violence ?",
			Type:        "guide",
			Category:    "Premiers secours",
			Summary:     "Étapes claires et numéros d'urgence à composer immédiatement en cas de violence physique, sexuelle ou domestique.",
			IsPublished: true,
		},
		{
			Title:       "Les droits de la femme en Burkina Faso — Fiches synthèse",
			Type:        "article",
			Category:    "Droits",
			Summary:     "Résumé des principaux droits protégés par la Constitution et les conventions internationales ratifiées par le Burkina Faso.",
			IsPublished: true,
		},
		{
			Title:       "Comment parler à un enfant victime de violence ?",
			Type:        "guide",
			Category:    "Protection enfants",
			Summary:     "Conseils pratiques à l'intention des parents, enseignants et travailleurs sociaux pour accompagner un enfant en détresse.",
			IsPublished: true,
		},
		{
			Title:       "Numéros d'urgence et structures d'aide — Affiche imprimable",
			Type:        "infographie",
			Category:    "Ressources pratiques",
			Summary:     "Affiche récapitulative de tous les numéros d'urgence (17, 15, 80000001) et des structures d'aide au Burkina Faso.",
			IsPublished: true,
		},
		{
			Title:       "Formation : Reconnaître les signes de violence domestique",
			Type:        "formation",
			Category:    "Formation professionnelle",
			Summary:     "Module de formation destiné aux enseignants, agents de santé et travailleurs sociaux pour identifier les situations de violence au foyer.",
			IsPublished: true,
		},
		{
			Title:       "Témoignages : paroles de survivantes de violences conjugales",
			Type:        "audio",
			Category:    "Témoignages",
			Summary:     "Recueil de témoignages audio de femmes qui ont surmonté des situations de violence et trouvé de l'aide grâce aux structures locales.",
			IsPublished: true,
		},
		{
			Title:       "Violence économique : reconnaître et agir",
			Type:        "article",
			Category:    "Sensibilisation",
			Summary:     "Article de fond sur la violence économique, souvent sous-déclarée, et les recours légaux disponibles au Burkina Faso.",
			IsPublished: true,
		},
		{
			Title:       "Code Pénal burkinabè — Extraits sur les infractions contre la personne",
			Type:        "loi",
			Category:    "Textes légaux",
			Summary:     "Articles du Code pénal burkinabè relatifs aux coups et blessures volontaires, abus sexuels, et violences domestiques.",
			IsPublished: true,
		},
		{
			Title:       "Cartographie des services d'aide VBG au Burkina Faso",
			Type:        "infographie",
			Category:    "Ressources pratiques",
			Summary:     "Carte interactive des structures d'aide (ONG, hôpitaux, commissariats, centres d'écoute) répartis sur l'ensemble du territoire.",
			IsPublished: true,
		},
		{
			Title:       "Module e-learning : Droits des femmes et VBG (4 heures)",
			Type:        "formation",
			Category:    "Formation professionnelle",
			Summary:     "Formation complète en ligne couvrant le cadre légal, l'identification des victimes et les bonnes pratiques d'accompagnement.",
			IsPublished: true,
		},
		{
			Title:       "Protocole national de prise en charge des victimes de VBG",
			Type:        "guide",
			Category:    "Protocoles",
			Summary:     "Document officiel décrivant le parcours de prise en charge médicale, psychosociale et juridique des victimes de VBG au Burkina Faso.",
			IsPublished: true,
		},
	}
	db.Create(&resources)
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
