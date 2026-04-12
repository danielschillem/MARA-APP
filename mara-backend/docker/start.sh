#!/bin/sh
set -e

cd /var/www/html

echo "==> Caching Laravel config / routes / views..."
php artisan config:cache
php artisan route:cache
php artisan view:cache

echo "==> Running database migrations..."
php artisan migrate --force

echo "==> Linking public storage..."
php artisan storage:link 2>/dev/null || true

echo "==> Configuring nginx on port ${PORT:-8000}..."
export PORT="${PORT:-8000}"
# ${PORT} only – leaves all other nginx $variables untouched
envsubst '${PORT}' \
    < /etc/nginx/http.d/default.conf.template \
    > /etc/nginx/http.d/default.conf

echo "==> Starting PHP-FPM..."
php-fpm -D

echo "==> Starting nginx (port ${PORT})..."
exec nginx -g 'daemon off;'
