## Secrets GitHub Actions à configurer

Va dans : **GitHub repo → Settings → Secrets and variables → Actions**

### 1. Render — Deploy Hook
| Secret | Valeur |
|--------|--------|
| `RENDER_DEPLOY_HOOK_URL` | Dashboard Render → Service mara-api → **Settings → Deploy Hooks** → Create hook → copier l'URL |

### 2. Netlify — Deploy Frontend
| Secret | Valeur |
|--------|--------|
| `NETLIFY_AUTH_TOKEN` | netlify.com → **User Settings → Personal access tokens** → New token |
| `NETLIFY_SITE_ID` | Netlify → Site → **Site configuration → Site ID** (format: `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`) |
| `VITE_API_URL` | `https://mara-api.onrender.com/api` (l'URL de ton API Render) |

### 3. Flutter APK Release
| Secret | Valeur |
|--------|--------|
| `ANDROID_KEYSTORE_BASE64` | `base64 -w 0 upload-keystore.jks` |
| `ANDROID_STORE_PASSWORD` | Mot de passe défini lors de `keytool` |
| `ANDROID_KEY_PASSWORD` | Mot de passe de la clé |
| `ANDROID_KEY_ALIAS` | `mara-key` |

---

## Générer le keystore Android (une seule fois)

```bash
keytool -genkey -v \
  -keystore upload-keystore.jks \
  -storetype JKS \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias mara-key
```

Puis encoder pour GitHub :
```bash
base64 -w 0 upload-keystore.jks
```

> ⚠️ Ne jamais committer `upload-keystore.jks` ni `android/key.properties` (déjà dans .gitignore)

---

## Configurer Render (premiere fois)

1. Connecte-toi sur [render.com](https://render.com)
2. **New → Blueprint** → sélectionne ton repo GitHub
3. Render détecte `render.yaml` automatiquement → **Apply**
4. Après le déploiement, copie l'URL (ex: `https://mara-api.onrender.com`)
5. Mets à jour dans `render.yaml` : `FRONTEND_URL` et `FLUTTER_URL`

---

## Configurer Netlify (premiere fois)

1. Connecte-toi sur [netlify.com](https://netlify.com)
2. **Import an existing project** → GitHub → sélectionne le repo
3. Netlify détecte `netlify.toml` automatiquement
4. **Site configuration → Environment variables** → Ajoute :
   - `VITE_API_URL` = `https://mara-api.onrender.com/api`
5. **Trigger deploy** → Vérifie que ça build correctement

---

## Build Flutter APK (release)

### Prérequis
- `android/upload-keystore.jks` présent (généré une seule fois via keytool)
- `android/key.properties` configuré (non commité — dans .gitignore)

### Commandes

```powershell
# Depuis mara-flutter/
cd "mara-flutter"

# Build APK release (production)
flutter build apk --release `
  --dart-define=API_URL=https://mara-api.onrender.com/api `
  --dart-define=WS_URL=wss://mara-api.onrender.com/api/ws

# Build APK local (dev)
flutter build apk --release `
  --dart-define=API_URL=http://10.0.2.2:8081/api `
  --dart-define=WS_URL=ws://10.0.2.2:8081/api/ws

# Build App Bundle (Play Store)
flutter build appbundle --release `
  --dart-define=API_URL=https://mara-api.onrender.com/api `
  --dart-define=WS_URL=wss://mara-api.onrender.com/api/ws
```

L'APK sera dans `build/app/outputs/flutter-apk/app-release.apk`

### Changer le mot de passe keystore avant production
Édite `android/key.properties` :
```
storePassword=VOTRE_NOUVEAU_MOT_DE_PASSE
keyPassword=VOTRE_NOUVEAU_MOT_DE_PASSE
keyAlias=mara-key
storeFile=../upload-keystore.jks
```

> ⚠️ `android/key.properties` et `*.jks` sont dans `.gitignore` — ne jamais les committer.
