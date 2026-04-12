# MARA Backend — API REST Laravel

API REST du projet MARA, construite avec **Laravel 12** et **Sanctum** pour l'authentification par tokens.

## Prérequis

- PHP >= 8.2
- Composer >= 2.x
- Extensions PHP : `pdo_sqlite`, `mbstring`, `openssl`, `tokenizer`, `xml`, `ctype`, `json`

## Installation

```bash
# Installer les dépendances
composer install

# Copier et configurer l'environnement
cp .env.example .env
php artisan key:generate

# Créer la base SQLite
touch database/database.sqlite          # Linux/Mac
New-Item database/database.sqlite       # Windows PowerShell

# Lancer les migrations avec les données de démonstration
php artisan migrate --seed

# Démarrer le serveur
php artisan serve
```

L'API est disponible sur **http://localhost:8000/api**.

## Configuration (.env)

```env
APP_NAME=MARA
APP_URL=http://localhost:8000
FRONTEND_URL=http://localhost:5173
DB_CONNECTION=sqlite
SANCTUM_STATEFUL_DOMAINS=localhost:5173
APP_LOCALE=fr
```

## Authentification

L'API utilise **Laravel Sanctum** avec des tokens Bearer.

```bash
# Connexion
POST /api/login
Content-Type: application/json
{"email": "admin@mara.bf", "password": "password"}

# Réponse
{"user": {...}, "token": "1|abc123..."}

# Requête authentifiée
GET /api/dashboard
Authorization: Bearer 1|abc123...
```

## Routes API (25 endpoints)

### Publiques

| Méthode | Endpoint | Contrôleur | Description |
|---------|----------|------------|-------------|
| POST | `/register` | AuthController@register | Inscription |
| POST | `/login` | AuthController@login | Connexion |
| GET | `/violence-types` | DirectoryController@violenceTypes | Types de violence |
| GET | `/sos-numbers` | DirectoryController@sosNumbers | Numéros d'urgence |
| GET | `/services` | DirectoryController@services | Annuaire des services |
| GET | `/resources` | ResourceController@index | Ressources (filtres : type, category) |
| GET | `/resources/{id}` | ResourceController@show | Détail ressource |
| POST | `/reports` | ReportController@store | Signalement (anonyme possible) |
| POST | `/conversations/anonymous` | ConversationController@startAnonymous | Chat anonyme |
| GET | `/conversations/{id}` | ConversationController@show | Conversation |
| GET | `/conversations/{id}/messages` | ConversationController@messages | Messages |
| POST | `/conversations/{id}/messages` | ConversationController@sendMessage | Envoyer message |

### Protégées (auth:sanctum)

| Méthode | Endpoint | Contrôleur | Description |
|---------|----------|------------|-------------|
| POST | `/logout` | AuthController@logout | Déconnexion |
| GET | `/me` | AuthController@me | Profil connecté |
| GET | `/dashboard` | DashboardController@index | Tableau de bord |
| GET | `/reports/stats` | ReportController@stats | Statistiques |
| GET | `/reports` | ReportController@index | Liste signalements (filtres : status, region, priority) |
| GET | `/reports/{id}` | ReportController@show | Détail signalement |
| PUT | `/reports/{id}` | ReportController@update | Modifier signalement |
| GET | `/conversations` | ConversationController@index | Liste conversations |
| POST | `/conversations` | ConversationController@store | Nouvelle conversation |
| POST | `/conversations/{id}/close` | ConversationController@close | Fermer conversation |
| POST | `/resources` | ResourceController@store | Créer ressource |
| PUT | `/resources/{id}` | ResourceController@update | Modifier ressource |
| DELETE | `/resources/{id}` | ResourceController@destroy | Supprimer ressource |

## Modèles Eloquent

| Modèle | Table | Relations principales |
|--------|-------|----------------------|
| **User** | `users` | hasMany(Report), hasMany(Conversation) |
| **Report** | `reports` | belongsToMany(ViolenceType), hasMany(ReportAttachment), belongsTo(User) |
| **ViolenceType** | `violence_types` | belongsToMany(Report) |
| **ReportAttachment** | `report_attachments` | belongsTo(Report) |
| **Conversation** | `conversations` | belongsTo(User), hasMany(Message) |
| **Message** | `messages` | belongsTo(Conversation), belongsTo(User) |
| **Resource** | `resources` | — |
| **ServiceDirectory** | `service_directories` | — |
| **SosNumber** | `sos_numbers` | — |

## Rôles utilisateur

| Rôle | Description |
|------|-------------|
| `admin` | Accès complet, gestion des signalements et ressources |
| `professionnel` | Consultation et traitement des signalements |
| `conseiller` | Chat avec les visiteurs, support |

## Base de données

### Tables principales

- **users** — Utilisateurs avec rôles (admin, professionnel, conseiller)
- **violence_types** — 10 types : physique, sexuelle, psychologique, économique, verbale, cyberviolence, négligence, mariage forcé, mutilation, traite
- **reports** — Signalements avec référence auto (`MARA-YYYY-XXXX`), statut, priorité, géolocalisation
- **report_violence_type** — Pivot reports ↔ violence_types (M:N)
- **report_attachments** — Pièces jointes aux signalements
- **conversations** — Chat anonyme (session_token UUID) ou authentifié
- **messages** — Messages de chat
- **resources** — Articles, vidéos, lois, guides, infographies, formations
- **service_directories** — Annuaire (ONG, sécurité, médical, juridique, institutionnel)
- **sos_numbers** — Numéros d'urgence triés

### Données de démonstration (Seeder)

Le seeder crée :
- 4 utilisateurs (1 admin, 2 professionnels, 1 conseillère)
- 10 types de violence avec icônes Lucide
- 5 numéros SOS (Ligne Verte, Police, SAMU, Pompiers, Action Sociale)
- 6 services d'aide
- 6 ressources éducatives

## Commandes utiles

```bash
php artisan serve                  # Démarrer le serveur (port 8000)
php artisan migrate --seed         # Migrer + données démo
php artisan migrate:fresh --seed   # Réinitialiser entièrement
php artisan route:list             # Lister les routes
php artisan test                   # Lancer les tests
php artisan tinker                 # Console interactive
```

## CORS

La configuration CORS (`config/cors.php`) autorise les requêtes depuis `FRONTEND_URL` (par défaut `http://localhost:5173`) avec support des credentials pour Sanctum.

## Tests

```bash
php artisan test
# ou
./vendor/bin/phpunit
```

## Version

| Version | Date | Description |
|---------|------|-------------|
| **1.0.0** | 14 mars 2026 | Release initiale — API REST 25 endpoints, 9 modèles, seeder complet |

## Auteur

**Baba Yaga** — Développeur Full Stack  
GitLab : [@Schillem](https://gitlab.com/Schillem)

## Licence

Tous droits réservés © 2026 Baba Yaga — Projet AIF (Association des Informaticiens du Faso) / Burkina Faso.
