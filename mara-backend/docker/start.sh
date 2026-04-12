#!/bin/sh
# Do NOT use set -e — let each step fail gracefully

cd /var/www/html

# ── Fix APP_KEY format (must start with base64:) ─────────────────────────────
if [ -n "$APP_KEY" ] && [ "${APP_KEY#base64:}" = "$APP_KEY" ]; then
  export APP_KEY="base64:$APP_KEY"
  echo "==> Prefixed APP_KEY with base64:"
fi

echo "==> Caching Laravel config / routes / views..."
php artisan config:cache  || echo "  [WARN] config:cache failed – continuing"
php artisan route:cache   || echo "  [WARN] route:cache failed – continuing"
php artisan view:cache    || echo "  [WARN] view:cache failed – continuing"

echo "==> Running database migrations..."
php artisan migrate --force || echo "  [WARN] migrate failed – continuing"

echo "==> Linking public storage..."
php artisan storage:link 2>/dev/null || true

echo "==> Configuring nginx on port ${PORT:-8000}..."
export PORT="${PORT:-8000}"
# Substitute ${PORT} only – all other nginx $variables stay untouched
envsubst '${PORT}' \
    < /etc/nginx/http.d/default.conf.template \
    > /etc/nginx/http.d/default.conf

echo "==> Starting PHP-FPM..."
php-fpm -D

# Wait until php-fpm is accepting connections before starting nginx
echo "==> Waiting for PHP-FPM to be ready..."
for i in $(seq 1 20); do
  if nc -z 127.0.0.1 9000 2>/dev/null; then
    echo "  PHP-FPM ready after ${i}s"
    break
  fi
  sleep 1
done

echo "==> Starting nginx (port ${PORT})..."
exec nginx -g 'daemon off;'
