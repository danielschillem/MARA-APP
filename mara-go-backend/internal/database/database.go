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
	// If old Côte d'Ivoire data exists (detected by region "Abidjan"), purge and reseed with BF data.
	var ciCount int64
	db.Model(&models.ServiceDirectory{}).Where("region = ?", "Abidjan").Count(&ciCount)
	if ciCount > 0 {
		db.Exec("DELETE FROM service_directories")
	}

	var count int64
	db.Model(&models.ServiceDirectory{}).Count(&count)
	if count > 0 {
		return
	}
	services := []models.ServiceDirectory{
		// Centre (Ouagadougou)
		{Name: "Police Nationale — Commissariat Central", Type: "securite", Region: "Centre", Phone: "17", Address: "Avenue de l'Indépendance, Ouagadougou", Description: "Commissariat central de Ouagadougou, disponible 24h/24", Lat: 12.3647, Lng: -1.5330},
		{Name: "Gendarmerie Nationale — Escadron de Ouaga", Type: "securite", Region: "Centre", Phone: "16", Address: "Avenue de la Grande Chancellerie, Ouagadougou", Description: "Gendarmerie nationale, recoit les plaintes de violences", Lat: 12.3660, Lng: -1.5350},
		{Name: "SAMU Burkina Faso", Type: "urgence", Region: "Centre", Phone: "15", Address: "CHU Yalgado Ouédraogo, Ouagadougou", Description: "Service d'aide médicale urgente, disponible 24h/24", Lat: 12.3620, Lng: -1.5202},
		{Name: "Pompiers — Bataillon National", Type: "urgence", Region: "Centre", Phone: "18", Address: "Avenue de la Résistance du 17 mai, Ouagadougou", Description: "Brigade nationale de sapeurs-pompiers", Lat: 12.3601, Lng: -1.5315},
		{Name: "Association Voix de Femmes", Type: "ong", Region: "Centre", Phone: "+226 25 33 44 55", Address: "Secteur 15, Ouagadougou", Description: "Association de défense des droits des femmes et des enfants", Lat: 12.3575, Lng: -1.5415},
		{Name: "AFJB — Association des Femmes Juristes du Burkina", Type: "juridique", Region: "Centre", Phone: "+226 25 33 12 30", Address: "Secteur 4, Ouagadougou", Description: "Aide juridique gratuite pour les femmes victimes de violence", Lat: 12.3640, Lng: -1.5380},
		{Name: "CHU Yalgado Ouédraogo", Type: "medical", Region: "Centre", Phone: "+226 25 30 66 44", Address: "Avenue de l'Oubritenga, Ouagadougou", Description: "Centre hospitalier universitaire, accueil urgences 24h/24", Lat: 12.3621, Lng: -1.5201},
		{Name: "Centre Médical Protestant — Ouagadougou", Type: "medical", Region: "Centre", Phone: "+226 25 34 03 55", Address: "Avenue de la Liberté, Ouagadougou", Description: "Centre médical privé avec unité de prise en charge VBG", Lat: 12.3590, Lng: -1.5250},
		{Name: "Ministère de la Femme, de la Solidarité Nationale et de la Famille", Type: "institutionnel", Region: "Centre", Phone: "+226 25 32 74 44", Address: "Avenue de l'Indépendance, Ouagadougou", Description: "Direction des affaires sociales et de la protection de la femme", Lat: 12.3680, Lng: -1.5280},
		{Name: "Barreau du Burkina Faso", Type: "juridique", Region: "Centre", Phone: "+226 25 30 67 37", Address: "Avenue de la Nation, Ouagadougou", Description: "Aide juridictionnelle et assistance gratuite aux victimes", Lat: 12.3655, Lng: -1.5260},
		{Name: "Centre d'Écoute et de Conseil Juridique (CECJ)", Type: "ong", Region: "Centre", Phone: "+226 25 36 13 47", Address: "Secteur 28, Ouagadougou", Description: "Écoute et conseil juridique gratuit pour femmes et enfants", Lat: 12.3530, Lng: -1.5400},
		// Hauts-Bassins (Bobo-Dioulasso)
		{Name: "Commissariat Régional Hauts-Bassins", Type: "securite", Region: "Hauts-Bassins", Phone: "17", Address: "Bobo-Dioulasso", Description: "Police nationale régionale Hauts-Bassins, plaintes 24h/24", Lat: 11.1771, Lng: -4.2979},
		{Name: "CHR Souro Sanou — Bobo-Dioulasso", Type: "medical", Region: "Hauts-Bassins", Phone: "+226 20 97 00 27", Address: "Boulevard de la Résistance, Bobo-Dioulasso", Description: "Centre hospitalier régional, urgences et prise en charge VBG", Lat: 11.1750, Lng: -4.2965},
		{Name: "Association AVVS Bobo", Type: "ong", Region: "Hauts-Bassins", Phone: "+226 20 97 11 22", Address: "Secteur 3, Bobo-Dioulasso", Description: "Aide aux victimes de violences sexuelles et domestiques", Lat: 11.1800, Lng: -4.3010},
		{Name: "Direction Régionale de la Femme — Hauts-Bassins", Type: "institutionnel", Region: "Hauts-Bassins", Phone: "+226 20 97 32 10", Address: "Bobo-Dioulasso", Description: "Service de protection de la femme et de la famille", Lat: 11.1760, Lng: -4.3000},
		// Centre-Nord
		{Name: "Direction Régionale de la Femme — Centre-Nord", Type: "institutionnel", Region: "Centre-Nord", Phone: "+226 40 45 00 11", Address: "Kaya", Description: "Service de protection de la femme et de l'enfant", Lat: 13.0939, Lng: -1.0867},
		{Name: "CHR de Kaya", Type: "medical", Region: "Centre-Nord", Phone: "+226 40 45 00 44", Address: "Kaya", Description: "Centre hospitalier régional du Centre-Nord", Lat: 13.0920, Lng: -1.0850},
		// Nord
		{Name: "Commissariat Provincial — Loroum", Type: "securite", Region: "Nord", Phone: "17", Address: "Titao", Description: "Police nationale provinciale du Loroum", Lat: 13.7694, Lng: -2.0760},
		{Name: "CHR de Ouahigouya", Type: "medical", Region: "Nord", Phone: "+226 40 55 00 24", Address: "Ouahigouya", Description: "Centre hospitalier régional du Nord", Lat: 13.5751, Lng: -2.4162},
		// Est
		{Name: "CHR de Fada N'Gourma", Type: "medical", Region: "Est", Phone: "+226 40 77 00 24", Address: "Fada N'Gourma", Description: "Centre hospitalier régional de l'Est, urgences VBG", Lat: 12.0583, Lng: 0.3463},
		{Name: "Direction Régionale de la Femme — Est", Type: "institutionnel", Region: "Est", Phone: "+226 40 77 12 33", Address: "Fada N'Gourma", Description: "Service d'action sociale et de protection de la famille", Lat: 12.0600, Lng: 0.3480},
		// Sahel
		{Name: "CHR de Dori", Type: "medical", Region: "Sahel", Phone: "+226 40 46 00 35", Address: "Dori", Description: "Centre hospitalier régional du Sahel", Lat: 14.0352, Lng: -0.0325},
		{Name: "Commissariat Provincial — Dori", Type: "securite", Region: "Sahel", Phone: "17", Address: "Dori", Description: "Police nationale provinciale du Sahel", Lat: 14.0340, Lng: -0.0310},
		// Boucle du Mouhoun
		{Name: "CHR de Dédougou", Type: "medical", Region: "Boucle du Mouhoun", Phone: "+226 20 52 13 26", Address: "Dédougou", Description: "Centre hospitalier régional de la Boucle du Mouhoun", Lat: 12.4629, Lng: -3.4636},
		// Cascades
		{Name: "CHR de Banfora", Type: "medical", Region: "Cascades", Phone: "+226 20 91 02 34", Address: "Banfora", Description: "Centre hospitalier régional des Cascades", Lat: 10.6323, Lng: -4.7651},
		{Name: "Gendarmerie — Brigade de Banfora", Type: "securite", Region: "Cascades", Phone: "16", Address: "Banfora", Description: "Brigade territoriale de gendarmerie de Banfora", Lat: 10.6300, Lng: -4.7630},
		// Centre-Est
		{Name: "CHR de Tenkodogo", Type: "medical", Region: "Centre-Est", Phone: "+226 40 71 01 44", Address: "Tenkodogo", Description: "Centre hospitalier régional du Centre-Est", Lat: 11.7800, Lng: -0.3700},
		// Centre-Ouest
		{Name: "CHR de Koudougou", Type: "medical", Region: "Centre-Ouest", Phone: "+226 25 44 05 11", Address: "Koudougou", Description: "Centre hospitalier régional du Centre-Ouest", Lat: 12.2548, Lng: -2.3631},
		{Name: "Maison de la Femme de Koudougou", Type: "ong", Region: "Centre-Ouest", Phone: "+226 25 44 18 90", Address: "Koudougou", Description: "Centre d'accueil, d'écoute et de formation pour femmes", Lat: 12.2555, Lng: -2.3650},
		// Sud-Ouest
		{Name: "CHR de Gaoua", Type: "medical", Region: "Sud-Ouest", Phone: "+226 20 87 00 62", Address: "Gaoua", Description: "Centre hospitalier régional du Sud-Ouest", Lat: 10.3236, Lng: -3.1770},
		// Plateau Central
		{Name: "CHR de Ziniaré", Type: "medical", Region: "Plateau Central", Phone: "+226 25 45 00 77", Address: "Ziniaré", Description: "Centre hospitalier régional du Plateau Central", Lat: 12.5754, Lng: -1.2906},
		// Centre-Sud
		{Name: "CHR de Manga", Type: "medical", Region: "Centre-Sud", Phone: "+226 40 43 00 51", Address: "Manga", Description: "Centre hospitalier régional du Centre-Sud", Lat: 11.6637, Lng: -1.0715},
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
