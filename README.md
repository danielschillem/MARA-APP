# MARA – Observatoire Électronique de Lutte contre les Violences faites aux Femmes et aux Enfants

> **M**onitoring **A**nd **R**eporting **A**pplication — Plateforme numérique dédiée à la lutte contre les violences basées sur le genre au Burkina Faso.
>
> **Stack actuelle :** Go 1.26 + React 19 + Flutter 3 — migration complète depuis Laravel (avril 2026)

---

## Présentation

MARA est une plateforme web permettant de :

- **Signaler** des violences de manière anonyme ou identifiée (formulaire multi-étapes)
- **Dialoguer** en direct avec un conseiller via un chat anonyme sécurisé
- **Consulter** un annuaire de services d'aide (ONG, police, santé, juridique)
- **Accéder** à des ressources éducatives (articles, guides, lois, vidéos)
- **Piloter** l'activité via un tableau de bord professionnel (statistiques, graphiques)
- **Observer** les données humanitaires via l'intégration ReliefWeb (Observatoire)
- **Appeler** les numéros d'urgence (Ligne Verte, Police, SAMU, Pompiers)

## Architecture

```
mara-app/
├── mara-go-backend/  ← API REST Go 1.26 + SQLite/PostgreSQL + WebSocket
├── mara-frontend/    ← SPA React 19 + Vite 8
├── mara-flutter/     ← Application mobile Flutter 3 (Android/iOS/Web)
├── MARA-plateforme.html  ← Maquette HTML d'origine
└── README.md
```

| Couche | Technologie | Port par défaut |
|--------|-------------|-----------------|
| Backend | Go 1.26 + JWT (golang-jwt) | `8081` |
| Frontend web | React 19 + Vite 8 | `5173` |
| Application mobile | Flutter 3 | `3000` (web) |
| Base de données | SQLite (dev) / PostgreSQL (prod) | — |
| Temps réel | WebSocket natif (gorilla/websocket) | `8081` |

## Prérequis

- **Go** >= 1.21 ([download](https://go.dev/dl/))
- **Node.js** >= 18.x et **npm** >= 9.x
- **Flutter** >= 3.x ([download](https://docs.flutter.dev/get-started/install))
- **Git**

## Installation rapide

### 1. Cloner le dépôt

```bash
git clone https://github.com/danielschillem/MARA-APP.git
cd mara-app
```

### 2. Backend (Go)

```bash
cd mara-go-backend

# Copier et configurer l'environnement
cp .env.example .env
# Éditer .env : JWT_SECRET, DATABASE_URL, FRONTEND_URL

# Installer les dépendances Go
go mod tidy

# Démarrer le serveur (avec seed de démo)
DB_SEED=true go run ./cmd/server
# ou sur Windows PowerShell :
$env:DB_SEED="true" ; go run ./cmd/server
```

Le backend est accessible sur **http://localhost:8081**.

### 3. Frontend (React)

```bash
cd mara-frontend

# Installer les dépendances
npm install

# Copier les variables d'environnement
cp .env.example .env

# Démarrer le serveur de développement (proxy auto vers :8081)
npm run dev
```

Le frontend est accessible sur **http://localhost:5173**.

### 4. Application mobile (Flutter) — optionnel

```bash
cd mara-flutter

# Récupérer les dépendances
flutter pub get

# Lancer en mode web (dev)
flutter run -d chrome

# Générer un APK Android
flutter build apk --release
```

## Variables d'environnement (Backend Go)

| Variable | Valeur par défaut | Description |
|----------|-------------------|-------------|
| `PORT` | `8081` | Port d'écoute du serveur |
| `APP_ENV` | `development` | Environnement (`development` / `production`) |
| `DATABASE_URL` | `file:mara.db?cache=shared&mode=rwc` | SQLite (dev) ou DSN PostgreSQL (prod) |
| `JWT_SECRET` | — | Clé secrète JWT (minimum 32 caractères) |
| `FRONTEND_URL` | `http://localhost:5173` | URL du frontend (CORS) |
| `FLUTTER_URL` | `http://localhost:3000` | URL app Flutter (CORS) |
| `DB_SEED` | `false` | `true` pour insérer des données de démo |
| `MAX_UPLOAD_MB` | `20` | Taille max des uploads en Mo |
| `UPLOAD_DIR` | `uploads` | Dossier de stockage des fichiers |

## Variables d'environnement (Frontend)

| Variable | Valeur par défaut | Description |
|----------|-------------------|-------------|
| `VITE_API_URL` | `/api` | URL de l'API backend (proxy Vite en dev) |

## Comptes de démonstration

Après démarrage avec `DB_SEED=true` :

| Rôle | Email | Mot de passe |
|------|-------|--------------|
| Administrateur | `admin@mara.bf` | `password` |
| Professionnelle (Psychologue) | `aminata@mara.bf` | `password` |
| Professionnel (Juriste) | `moussa@mara.bf` | `password` |
| Conseillère | `fatou@mara.bf` | `password` |

## Référence API

Base URL : `http://localhost:8081/api`

### Routes publiques

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| `POST` | `/register` | Inscription utilisateur |
| `POST` | `/login` | Connexion (retourne un token Bearer) |
| `GET` | `/violence-types` | Liste des types de violence |
| `GET` | `/sos-numbers` | Numéros d'urgence |
| `GET` | `/services` | Annuaire des services |
| `GET` | `/resources` | Ressources éducatives |
| `GET` | `/resources/{id}` | Détail d'une ressource |
| `POST` | `/reports` | Créer un signalement (anonyme possible) |
| `POST` | `/conversations/anonymous` | Démarrer un chat anonyme |
| `GET` | `/conversations/{id}` | Voir une conversation |
| `GET` | `/conversations/{id}/messages` | Messages d'une conversation |
| `POST` | `/conversations/{id}/messages` | Envoyer un message |
| `GET` | `/reports/track/{ref}` | Suivi par référence |
| `GET` | `/announcements` | Annonces actives |
| `GET` | `/observatory/stats` | Statistiques observatoire ReliefWeb |
| `GET` | `/observatory/reports` | Rapports observatoire (paginé, filtres) |

### Routes protégées (Bearer Token)

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| `POST` | `/logout` | Déconnexion |
| `GET` | `/me` | Profil utilisateur connecté |
| `GET` | `/dashboard` | Statistiques du tableau de bord |
| `GET` | `/reports/stats` | Statistiques des signalements |
| `GET` | `/reports` | Liste des signalements (filtres : status, region, priority) |
| `GET` | `/reports/{id}` | Détail d'un signalement |
| `PUT` | `/reports/{id}` | Modifier un signalement |
| `GET` | `/conversations` | Liste des conversations |
| `POST` | `/conversations` | Créer une conversation authentifiée |
| `POST` | `/conversations/{id}/close` | Clôturer une conversation |
| `POST` | `/resources` | Créer une ressource |
| `PUT` | `/resources/{id}` | Modifier une ressource |
| `DELETE` | `/resources/{id}` | Supprimer une ressource |
| `POST` | `/change-password` | Changer le mot de passe |
| `POST` | `/conversations/{id}/assign` | Assigner un conseiller |
| `POST` | `/observatory/sync` | Synchroniser les données ReliefWeb (admin) |

### Authentification

```bash
# Connexion
curl -X POST http://localhost:8081/api/login \
  -H "Content-Type: application/json" \
  -d '{"email": "admin@mara.bf", "password": "password"}'

# Réponse → { "user": {...}, "token": "eyJhbGci..." }

# Requête authentifiée
curl http://localhost:8081/api/dashboard \
  -H "Authorization: Bearer eyJhbGci..."
```

## Modèle de données

```
┌──────────────┐     ┌──────────────────┐     ┌──────────────────┐
│    users     │     │    reports       │     │ violence_types   │
├──────────────┤     ├──────────────────┤     ├──────────────────┤
│ id           │◄────┤ assigned_to (FK) │     │ id               │
│ name         │     │ reference        │     │ slug             │
│ email        │     │ reporter_type    │     │ label_fr         │
│ role         │     │ victim_gender    │     │ icon             │
│ titre        │     │ region           │     └────────┬─────────┘
│ specialite   │     │ description      │              │ M:N
│ organisation │     │ status           │     ┌────────┴─────────┐
│ is_online    │     │ priority         │     │ report_violence  │
└──────┬───────┘     └────────┬─────────┘     │ _type (pivot)    │
       │                      │               └──────────────────┘
       │              ┌───────┴────────┐
       │              │ report_        │
       │              │ attachments    │
       │              └────────────────┘
       │
┌──────┴───────┐     ┌──────────────────┐
│conversations │────►│   messages       │
├──────────────┤     ├──────────────────┤
│ user_id (FK) │     │ conversation_id  │
│ conseiller_id│     │ sender_id (FK)   │
│ session_token│     │ is_from_visitor  │
│ status       │     │ body             │
└──────────────┘     └──────────────────┘

┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐
│   resources      │  │service_directories│  │   sos_numbers    │
├──────────────────┤  ├──────────────────┤  ├──────────────────┤
│ title            │  │ name             │  │ label            │
│ type             │  │ type             │  │ number           │
│ category         │  │ region           │  │ icon             │
│ url              │  │ phone            │  │ sort_order       │
└──────────────────┘  └──────────────────┘  └──────────────────┘
```

## Pages du frontend

| Page | Route | Description |
|------|-------|-------------|
| Accueil | `/` | Landing page avec SOS, héros, fonctionnalités, statistiques |
| Signaler | `/signaler` | Formulaire multi-étapes (5 étapes) avec suivi de référence |
| Chat | `/chat` | Chat anonyme en temps réel avec un conseiller |
| Suivi | `/suivi` | Suivi de signalement par référence |
| Ressources | `/ressources` | Articles, guides, lois, vidéos filtrables par type |
| Annuaire | `/annuaire` | SOS + annuaire de services avec filtres par type/région |
| Observatoire | `/observatoire` | Dashboard ReliefWeb (stats, tendances, rapports) |
| Dashboard | `/dashboard` | Tableau de bord pro avec graphiques Recharts (protégé) |
| Signalements | `/signalements` | Gestion et suivi des signalements (protégé) |
| Conversations | `/conversations` | Gestion des conversations conseiller (protégé) |
| Profil | `/profil` | Paramètres du profil utilisateur (protégé) |
| Connexion | `/login` | Espace professionnel |
| Inscription | `/register` | Création de compte professionnel |
| 404 | `*` | Page introuvable avec navigation |

## Stack technique

### Backend (Go)
- **Go 1.26** — Language de programmation système
- **go-chi/chi v5** — Router HTTP léger et rapide
- **golang-jwt/jwt v5** — Authentification par tokens JWT (Bearer)
- **gorilla/websocket** — WebSocket natif pour le chat temps réel
- **gorm.io/gorm** — ORM avec drivers SQLite et PostgreSQL
- **glebarez/sqlite** — Driver SQLite pur Go (sans cgo)
- **joho/godotenv** — Chargement des variables d'environnement
- **golang.org/x/crypto** — Hachage bcrypt des mots de passe

### Frontend (React)
- **React 19** — Bibliothèque UI
- **Vite 8** — Outil de build avec proxy dev vers :8081
- **React Router DOM 7** — Routage SPA avec routes protégées
- **Axios** — Client HTTP avec intercepteurs JWT
- **Recharts 3** — Graphiques (PieChart, BarChart, AreaChart, LineChart)
- **Lucide React** — Bibliothèque d'icônes SVG
- **react-i18next** — Internationalisation (français)
- **Tailwind CSS 4** — Utilitaires CSS avec dark mode

### Mobile (Flutter)
- **Flutter 3** — Framework UI multiplateforme (Android, iOS, Web)
- **Dart** — Langage de programmation
- **http** — Client HTTP pour l'API Go
- **go_router** — Routage déclaratif

### Design
- **Charte graphique** : Violet (`#7B2FBE`) / Orange (`#E8541E`)
- **Police** : Poppins (Google Fonts)
- **Dark mode** : Basculement clair/sombre avec persistance
- **Responsive** : Breakpoints 480px / 768px / 1024px
- **Accessibilité** : Skip-link, aria-labels, focus-visible, reduced-motion

## Tests

```bash
# Backend Go
cd mara-go-backend
go test ./...

# Frontend React
cd mara-frontend
npx vitest run

# Flutter
cd mara-flutter
flutter test
```

## Scripts utiles

```bash
# Backend Go
cd mara-go-backend
go run ./cmd/server        # Démarrer l'API
DB_SEED=true go run ./cmd/server  # Démarrer avec données de démo
go build -o mara-api ./cmd/server # Compiler un binaire
go test ./...              # Lancer les tests Go
go mod tidy                # Nettoyer les dépendances

# Frontend
cd mara-frontend
npm run dev                # Serveur de développement (proxy :8081)
npm run build              # Build de production
npm run preview            # Prévisualiser le build
npm run lint               # Vérifier le code

# Flutter
cd mara-flutter
flutter pub get            # Installer les dépendances
flutter run -d chrome      # Lancer en mode web
flutter build apk          # Générer APK Android
flutter build ios          # Générer IPA iOS
flutter analyze lib/       # Analyser le code Dart
```

## Structure détaillée

<details>
<summary><strong>Backend Go — mara-go-backend/</strong></summary>

```
mara-go-backend/
├── cmd/
│   └── server/            # Point d'entrée main.go
├── internal/
│   ├── config/            # Chargement des variables d'environnement
│   ├── database/          # Init GORM + migrations auto + seeding
│   ├── handlers/          # Handlers HTTP (auth, reports, conversations, etc.)
│   ├── middleware/        # JWT, CORS, rate limiting
│   ├── models/            # Modèles GORM (User, Report, Conversation, Message…)
│   ├── services/          # Logique métier (ReliefWeb, upload, etc.)
│   └── websocket/         # Hub WebSocket pour le chat temps réel
├── uploads/               # Fichiers uploadés (audio, pièces jointes)
├── mara.db                # Base SQLite (dev, gitignorée)
├── .env.example
├── go.mod
├── go.sum
├── Makefile
└── Dockerfile
```

</details>

<details>
<summary><strong>Frontend — mara-frontend/</strong></summary>

```
mara-frontend/
├── public/
│   └── logo-mara.jpeg               # Logo MARA
├── src/
│   ├── api.js                       # Instance Axios + intercepteurs JWT
│   ├── App.jsx                      # Router principal
│   ├── main.jsx                     # Point d'entrée
│   ├── index.css                    # Système de design complet
│   ├── components/
│   │   ├── DynamicIcon.jsx          # Mapper noms d'icônes → composants Lucide
│   │   ├── IconBadge.jsx            # Badge icône réutilisable
│   │   ├── Layout.jsx               # Navbar, footer, dark mode, bouton sortie rapide
│   │   ├── ProtectedRoute.jsx       # Garde de route (redirige vers /login)
│   │   └── Toast.jsx                # Notifications toast avec contexte
│   ├── contexts/
│   │   └── AuthContext.jsx          # État d'authentification global
│   ├── i18n/
│   │   ├── index.js                 # Configuration i18next
│   │   └── fr.json                  # Traductions françaises
│   ├── pages/
│   │   ├── HomePage.jsx             # Page d'accueil
│   │   ├── ReportPage.jsx           # Formulaire de signalement (5 étapes)
│   │   ├── TrackingPage.jsx         # Suivi de signalement
│   │   ├── ChatPage.jsx             # Chat anonyme WebSocket
│   │   ├── DashboardPage.jsx        # Tableau de bord (graphiques)
│   │   ├── AdminPage.jsx            # Administration
│   │   ├── AlertsPage.jsx           # Alertes
│   │   ├── TeamPage.jsx             # Gestion équipe
│   │   ├── CounselorChatPage.jsx    # Gestion conversations conseiller
│   │   ├── ReportManagementPage.jsx # Gestion signalements pro
│   │   ├── ResourcesPage.jsx        # Ressources éducatives
│   │   ├── DirectoryPage.jsx        # Annuaire & numéros SOS
│   │   ├── ObservatoryPage.jsx      # Observatoire ReliefWeb (3 onglets)
│   │   ├── ProfilePage.jsx          # Profil utilisateur
│   │   ├── LoginPage.jsx            # Connexion professionnelle
│   │   ├── RegisterPage.jsx         # Inscription
│   │   └── NotFoundPage.jsx         # Page 404
│   └── utils/                       # Utilitaires partagés
└── vite.config.js                   # Proxy /api → :8081
```

</details>

<details>
<summary><strong>Mobile — mara-flutter/</strong></summary>

```
mara-flutter/
├── lib/                   # Code Dart source
├── assets/                # Images, icônes, fonts
├── android/               # Config Android
├── ios/                   # Config iOS
├── web/                   # Config web Flutter
├── test/                  # Tests Dart
└── pubspec.yaml           # Dépendances Flutter
```

</details>

## Dépôt GitHub

- **URL** : https://github.com/danielschillem/MARA-APP
- **Branche principale** : `main`

## Version

| Version | Date | Description |
|---------|------|-------------|
| **1.0.0** | 14 mars 2026 | Release initiale — API REST Laravel + SPA React (Sprints 0-4) |
| **1.1.0** | 14 mars 2026 | Sprint 5 — Sécurité & UX (rate limiting, dark mode, accessibilité) |
| **1.2.0** | 14 mars 2026 | Sprint 6 — Production (59 tests PHPUnit, observatoire ReliefWeb) |
| **2.0.0** | 13 avril 2026 | **Migration Go** — Backend Go 1.26 + JWT + WebSocket + Flutter mobile |

## Feuille de route (Roadmap)

### 🚀 Déploiement
| Priorité | Tâche | Détails |
|----------|-------|---------|
| 🔴 | Hébergement backend | Serveur PHP 8.2+ / MySQL ou PostgreSQL (VPS, Railway, DigitalOcean) |
| 🔴 | Hébergement frontend | Build statique sur Vercel, Netlify ou même serveur |
| 🔴 | Nom de domaine | Ex : `mara-bf.org` |
| 🔴 | Certificat SSL | HTTPS obligatoire (Let's Encrypt) |
| 🔴 | Migration SQLite → MySQL/PostgreSQL | Base de données de production |

### ⚡ Améliorations fonctionnelles
| Priorité | Tâche | Détails |
|----------|-------|---------|
| 🟠 | Notifications email | Alertes aux professionnels sur signalements urgents |
| 🟠 | Export PDF/CSV | Statistiques et signalements exportables |
| 🟡 | Chat temps réel | WebSockets via Laravel Reverb ou Pusher (remplacer le polling) |
| 🟡 | Upload pièces jointes | Photos/documents dans les signalements |
| 🟡 | Tableau de bord admin | Gestion des utilisateurs, rôles, modération |

### 🔒 Qualité & Sécurité
| Priorité | Tâche | Détails |
|----------|-------|---------|
| 🟠 | Tests frontend | Vitest + React Testing Library |
| 🟠 | CI/CD | Pipeline GitLab (tests auto, build, déploiement) |
| 🟠 | Audit sécurité | Pentest, vérification OWASP complète |
| 🟡 | Sauvegarde automatique | Backup régulier de la base de données |

### 📝 Contenu & Internationalisation
| Priorité | Tâche | Détails |
|----------|-------|---------|
| 🟠 | Données réelles | Services, ressources, numéros SOS à jour pour le Burkina Faso |
| 🟡 | Traductions | Compléter l'anglais, ajouter le mooré et le dioula |

> 🔴 Critique · 🟠 Important · 🟡 Souhaitable

## Auteur

**Baba Yaga** — Développeur Full Stack  
GitLab : [@Schillem](https://gitlab.com/Schillem)

## Licence

Ce projet est développé dans le cadre de l'initiative AIF (Association des Informaticiens du Faso) pour la lutte contre les violences basées sur le genre au Burkina Faso.  
Tous droits réservés © 2026 Baba Yaga.
