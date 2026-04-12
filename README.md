# MARA – Observatoire Électronique de Lutte contre les Violences faites aux Femmes et aux Enfants

> **M**onitoring **A**nd **R**eporting **A**pplication — Plateforme numérique dédiée à la lutte contre les violences basées sur le genre au Burkina Faso.

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
├── mara-backend/     ← API REST Laravel 12 (PHP 8.2+)
├── mara-frontend/    ← SPA React 19 + Vite 8
├── MARA-plateforme.html  ← Maquette HTML d'origine
└── README.md
```

| Couche    | Technologie             | Port par défaut |
|-----------|-------------------------|-----------------|
| Backend   | Laravel 12 + Sanctum    | `8000`          |
| Frontend  | React 19 + Vite 8       | `5173`          |
| Base de données | SQLite (dev) / MySQL/PostgreSQL (prod) | — |

## Prérequis

- **PHP** >= 8.2 avec extensions : `pdo_sqlite`, `mbstring`, `openssl`, `tokenizer`, `xml`, `ctype`, `json`
- **Composer** >= 2.x
- **Node.js** >= 18.x et **npm** >= 9.x
- **Git**

## Installation rapide

### 1. Cloner le dépôt

```bash
git clone https://gitlab.com/Schillem/mara-app.git
cd mara-app
```

### 2. Backend (Laravel)

```bash
cd mara-backend

# Installer les dépendances PHP
composer install

# Configurer l'environnement
cp .env.example .env
php artisan key:generate

# Créer la base SQLite
touch database/database.sqlite   # Linux/Mac
# ou: New-Item database/database.sqlite  # Windows PowerShell

# Lancer les migrations et le seeding
php artisan migrate --seed

# Démarrer le serveur API
php artisan serve
```

Le backend est accessible sur **http://localhost:8000**.

### 3. Frontend (React)

```bash
cd mara-frontend

# Installer les dépendances
npm install

# Démarrer le serveur de développement
npm run dev
```

Le frontend est accessible sur **http://localhost:5173**.

## Variables d'environnement (Backend)

| Variable | Valeur par défaut | Description |
|----------|-------------------|-------------|
| `APP_NAME` | `MARA` | Nom de l'application |
| `APP_URL` | `http://localhost:8000` | URL du backend |
| `FRONTEND_URL` | `http://localhost:5173` | URL du frontend (CORS) |
| `DB_CONNECTION` | `sqlite` | Driver de base de données |
| `SANCTUM_STATEFUL_DOMAINS` | `localhost:5173` | Domaines Sanctum |

## Variables d'environnement (Frontend)

| Variable | Valeur par défaut | Description |
|----------|-------------------|-------------|
| `VITE_API_URL` | `http://localhost:8000/api` | URL de l'API backend |

## Comptes de démonstration

Après le seeding (`php artisan migrate --seed`) :

| Rôle | Email | Mot de passe |
|------|-------|--------------|
| Administrateur | `admin@mara.bf` | `password` |
| Professionnelle (Psychologue) | `aminata@mara.bf` | `password` |
| Professionnel (Juriste) | `moussa@mara.bf` | `password` |
| Conseillère | `fatou@mara.bf` | `password` |

## Référence API

Base URL : `http://localhost:8000/api`

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
curl -X POST http://localhost:8000/api/login \
  -H "Content-Type: application/json" \
  -d '{"email": "admin@mara.bf", "password": "password"}'

# Réponse → { "user": {...}, "token": "1|abc123..." }

# Requête authentifiée
curl http://localhost:8000/api/dashboard \
  -H "Authorization: Bearer 1|abc123..."
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

### Backend
- **Laravel 12** — Framework PHP
- **Laravel Sanctum 4.3** — Authentification API par tokens
- **SQLite** — Base de données (développement)
- **Eloquent ORM** — 9 modèles avec relations

### Frontend
- **React 19** — Bibliothèque UI
- **Vite 8** — Outil de build
- **React Router DOM 7** — Routage SPA avec routes protégées
- **Axios** — Client HTTP avec intercepteurs
- **Recharts 3** — Graphiques (PieChart, BarChart, AreaChart, LineChart)
- **Lucide React** — Bibliothèque d'icônes SVG
- **react-i18next** — Internationalisation (français)
- **Tailwind CSS 4** — Utilitaires CSS avec dark mode

### Design
- **Charte graphique** : Violet (`#7B2FBE`) / Orange (`#E8541E`)
- **Police** : Poppins (Google Fonts)
- **Dark mode** : Basculement clair/sombre avec persistance
- **Responsive** : Breakpoints 480px / 768px / 1024px
- **Accessibilité** : Skip-link, aria-labels, focus-visible, reduced-motion

## Tests

```bash
cd mara-backend
php artisan test
```

**59 tests — 155 assertions** couvrant :

| Suite | Tests | Ce qui est testé |
|-------|-------|------------------|
| AuthTest | 12 | Inscription (mot de passe fort), connexion, déconnexion, profil, changement mdp |
| ReportTest | 11 | Signalement anonyme, référence auto, auto-escalade, suivi, validation, gestion |
| ConversationTest | 11 | Chat anonyme, messages, polling, assignation, fermeture, auth token |
| DashboardTest | 4 | Auth requise, statistiques, comptage |
| DirectoryTest | 6 | Types de violence, SOS, services + filtres (type, recherche, région) |
| ObservatoryTest | 6 | Stats vides/remplies, pagination, filtres (recherche, source), auth sync |
| ResourceTest | 7 | Liste publiée, filtres (type, recherche), CRUD (auth requis) |

## Scripts utiles

```bash
# Backend
cd mara-backend
php artisan serve              # Démarrer l'API
php artisan migrate --seed     # Créer les tables + données démo
php artisan migrate:fresh --seed  # Réinitialiser la base
php artisan route:list         # Voir toutes les routes API
php artisan test               # Lancer les tests PHPUnit

# Frontend
cd mara-frontend
npm run dev                    # Serveur de développement
npm run build                  # Build de production
npm run preview                # Prévisualiser le build
npm run lint                   # Vérifier le code
```

## Structure détaillée

<details>
<summary><strong>Backend — mara-backend/</strong></summary>

```
mara-backend/
├── app/
│   ├── Http/Controllers/Api/
│   │   ├── AuthController.php        # Inscription, connexion, déconnexion, changement mdp
│   │   ├── ConversationController.php # Chat anonyme et authentifié
│   │   ├── DashboardController.php   # Statistiques agrégées
│   │   ├── DirectoryController.php   # Services, SOS, types de violence
│   │   ├── ObservatoryController.php # Observatoire ReliefWeb (stats, rapports, sync)
│   │   ├── ReportController.php      # CRUD signalements
│   │   └── ResourceController.php    # CRUD ressources
│   ├── Models/
│   │   ├── Conversation.php
│   │   ├── Message.php
│   │   ├── ReliefWebReport.php       # Données ReliefWeb synchronisées
│   │   ├── Report.php               # Génère auto la référence MARA-YYYY-XXXX
│   │   ├── ReportAttachment.php
│   │   ├── Resource.php
│   │   ├── ServiceDirectory.php
│   │   ├── SosNumber.php
│   │   ├── User.php                 # HasApiTokens, rôles: admin|professionnel|conseiller
│   │   └── ViolenceType.php
│   ├── Services/
│   │   └── ReliefWebService.php     # Intégration API ReliefWeb
│   └── Providers/
├── config/
│   └── cors.php                     # Configuration CORS pour le frontend
├── database/
│   ├── migrations/                  # 7 fichiers de migration
│   └── seeders/
│       └── DatabaseSeeder.php       # Données démo complètes
├── routes/
│   └── api.php                      # 30+ routes API
└── .env.example
```

</details>

<details>
<summary><strong>Frontend — mara-frontend/</strong></summary>

```
mara-frontend/
├── public/
│   └── logo-mara.jpeg               # Logo MARA
├── src/
│   ├── api.js                       # Instance Axios + intercepteurs
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
│   └── pages/
│       ├── HomePage.jsx             # Page d'accueil
│       ├── ReportPage.jsx           # Formulaire de signalement (5 étapes)
│       ├── TrackingPage.jsx         # Suivi de signalement
│       ├── ChatPage.jsx             # Chat anonyme
│       ├── DashboardPage.jsx        # Tableau de bord (graphiques)
│       ├── CounselorChatPage.jsx    # Gestion conversations conseiller
│       ├── ReportManagementPage.jsx # Gestion signalements pro
│       ├── ResourcesPage.jsx        # Ressources éducatives
│       ├── DirectoryPage.jsx        # Annuaire & numéros SOS
│       ├── ObservatoryPage.jsx      # Observatoire ReliefWeb (3 onglets)
│       ├── ProfilePage.jsx          # Profil utilisateur
│       ├── LoginPage.jsx            # Connexion professionnelle
│       ├── RegisterPage.jsx         # Inscription
│       └── NotFoundPage.jsx         # Page 404
└── vite.config.js
```

</details>

## Dépôt GitLab

- **URL** : https://gitlab.com/Schillem/mara-app
- **Branche principale** : `main`

## Version

| Version | Date | Description |
|---------|------|-------------|
| **1.0.0** | 14 mars 2026 | Release initiale — API REST + SPA (Sprints 0-4) |
| **1.1.0** | 14 mars 2026 | Sprint 5 — Sécurité & UX (rate limiting, password strength, dark mode, accessibilité) |
| **1.2.0** | 14 mars 2026 | Sprint 6 — Production (59 tests PHPUnit, routes protégées, page 404, observatoire ReliefWeb) |

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
