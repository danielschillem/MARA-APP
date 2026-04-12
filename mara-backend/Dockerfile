# ──────────────────────────────────────────
#  MARA – Laravel API  |  PHP 8.2 + nginx
# ──────────────────────────────────────────
FROM php:8.2-fpm-alpine

# ---------- system dependencies ----------
RUN apk add --no-cache \
    nginx \
    libpq-dev \
    libzip-dev \
    oniguruma-dev \
    icu-dev \
    icu-libs \
    git \
    curl \
    zip \
    unzip \
    gettext \
    dos2unix

# ---------- PHP extensions ----------
RUN docker-php-ext-install \
    pdo \
    pdo_pgsql \
    zip \
    mbstring \
    opcache \
    bcmath \
    intl \
    pcntl

# OPcache – production tuning
RUN { \
    echo "opcache.enable=1"; \
    echo "opcache.memory_consumption=128"; \
    echo "opcache.max_accelerated_files=10000"; \
    echo "opcache.revalidate_freq=0"; \
    echo "opcache.validate_timestamps=0"; \
    } > /usr/local/etc/php/conf.d/opcache.ini

# ---------- Composer ----------
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

# ---------- Install PHP dependencies (cached layer) ----------
COPY --chown=www-data:www-data composer.json composer.lock ./
RUN composer install \
    --no-dev \
    --no-interaction \
    --prefer-dist \
    --no-scripts \
    --no-autoloader

# ---------- Copy application source ----------
COPY --chown=www-data:www-data . .

# Generate optimised autoloader + run package discovery
RUN composer dump-autoload --optimize \
    && php artisan package:discover --ansi 2>/dev/null || true

# Ensure writable directories exist with correct ownership
RUN chown -R www-data:www-data storage bootstrap/cache \
    && chmod -R 775 storage bootstrap/cache \
    && mkdir -p storage/app/public \
    storage/framework/cache/data \
    storage/framework/sessions \
    storage/framework/views \
    storage/logs

# ---------- nginx configuration ----------
COPY docker/nginx.conf.template /etc/nginx/http.d/default.conf.template
RUN rm -f /etc/nginx/http.d/default.conf

# ---------- startup script ----------
COPY docker/start.sh /start.sh
# Ensure LF line endings (safe on any OS)
RUN dos2unix /start.sh && chmod +x /start.sh

EXPOSE 8000

CMD ["/start.sh"]
