# MARA Frontend — SPA React

Interface utilisateur du projet MARA, construite avec **React 19** et **Vite 8**.

## Prérequis

- Node.js >= 18.x
- npm >= 9.x

## Installation

```bash
# Installer les dépendances
npm install

# Démarrer le serveur de développement
npm run dev
```

L'application est disponible sur **http://localhost:5173**.

## Scripts

| Commande | Description |
|----------|-------------|
| `npm run dev` | Serveur de développement avec HMR |
| `npm run build` | Build de production (dans `dist/`) |
| `npm run preview` | Prévisualiser le build |
| `npm run lint` | Vérification ESLint |

## Configuration

L'API backend est configurée dans `src/api.js` :

```javascript
baseURL: 'http://localhost:8000/api'
```

L'instance Axios inclut :
- Un intercepteur qui ajoute le header `Authorization: Bearer <token>` automatiquement
- Une gestion du 401 qui déconnecte l'utilisateur et redirige vers `/login`

## Pages

| Composant | Route | Description |
|-----------|-------|-------------|
| `HomePage` | `/` | Page d'accueil — bandeau SOS, héros, fonctionnalités, statistiques d'impact |
| `ReportPage` | `/signaler` | Formulaire de signalement en 5 étapes (identité → violence → détails → contact → confirmation) |
| `ChatPage` | `/chat` | Chat anonyme avec un conseiller (session UUID) |
| `DashboardPage` | `/dashboard` | Tableau de bord professionnel avec graphiques Recharts (accès authentifié) |
| `ResourcesPage` | `/ressources` | Ressources éducatives filtrables par type (article, vidéo, loi, guide…) |
| `DirectoryPage` | `/annuaire` | Numéros d'urgence SOS + annuaire de services avec filtres |
| `LoginPage` | `/login` | Connexion à l'espace professionnel |
| `RegisterPage` | `/register` | Inscription nouveau professionnel |

## Composants partagés

| Composant | Rôle |
|-----------|------|
| `Layout` | Navbar avec logo MARA, navigation, bouton sortie rapide, footer |
| `DynamicIcon` | Résout un nom d'icône (string depuis l'API) vers un composant Lucide React |

## Contextes

| Contexte | Rôle |
|----------|------|
| `AuthContext` | État d'authentification global (login, register, logout, user, token) avec persistance localStorage |

## Design system

- **Couleurs** : Violet `#7B2FBE` (primaire), Orange `#E8541E` (accent)
- **Police** : Poppins (Google Fonts)
- **Icônes** : Lucide React
- **Graphiques** : Recharts (PieChart, BarChart)
- **CSS** : Système custom dans `src/index.css` (pas de framework CSS)
- **Responsive** : Grilles adaptatives, media queries

## Dépendances

| Package | Version | Usage |
|---------|---------|-------|
| `react` | ^19.2 | Framework UI |
| `react-dom` | ^19.2 | Rendu DOM |
| `react-router-dom` | ^7.13 | Routage SPA |
| `axios` | ^1.13 | Client HTTP |
| `recharts` | ^3.8 | Graphiques |
| `lucide-react` | ^0.577 | Icônes SVG |

## Structure

```
src/
├── api.js                  # Instance Axios + intercepteurs
├── App.jsx                 # Router (BrowserRouter + Routes)
├── main.jsx                # Point d'entrée React
├── index.css               # Système de design complet
├── components/
│   ├── DynamicIcon.jsx     # Mapping noms → icônes Lucide
│   └── Layout.jsx          # Navbar + footer + sortie rapide
├── contexts/
│   └── AuthContext.jsx     # Authentification globale
└── pages/
    ├── HomePage.jsx
    ├── ReportPage.jsx
    ├── ChatPage.jsx
    ├── DashboardPage.jsx
    ├── ResourcesPage.jsx
    ├── DirectoryPage.jsx
    ├── LoginPage.jsx
    └── RegisterPage.jsx
```

## Build de production

```bash
npm run build
```

Génère les fichiers optimisés dans `dist/`. Servir avec n'importe quel serveur statique (Nginx, Apache, Vercel, Netlify…).

## Version

| Version | Date | Description |
|---------|------|-------------|
| **1.0.0** | 14 mars 2026 | Release initiale — SPA React 19, 9 pages, auth Sanctum |

## Auteur

**Baba Yaga** — Développeur Full Stack  
GitLab : [@Schillem](https://gitlab.com/Schillem)

## Licence

Tous droits réservés © 2026 Baba Yaga — Projet AIF (Association des Informaticiens du Faso) / Burkina Faso.
