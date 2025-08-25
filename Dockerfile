# Multi-stage build for OJS
FROM php:8.2-fpm-alpine AS base

# Install system dependencies
RUN apk add --no-cache \
    nginx \
    supervisor \
    curl \
    zip \
    unzip \
    git \
    freetype-dev \
    libjpeg-turbo-dev \
    libpng-dev \
    libxml2-dev \
    libxslt-dev \
    icu-dev \
    libzip-dev \
    postgresql-dev \
    mysql-client \
    postgresql-client \
    oniguruma-dev \
    nodejs \
    npm \
    gettext \
    curl

# Install PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-configure pgsql -with-pgsql=/usr/local/pgsql \
    && docker-php-ext-install -j$(nproc) \
        gd \
        mysqli \
        pdo_mysql \
        pgsql \
        pdo_pgsql \
        zip \
        xml \
        xsl \
        intl \
        opcache \
        bcmath \
        mbstring \
        ftp

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Production stage
FROM base AS production

# Set working directory
WORKDIR /var/www/html

# Copy application files
COPY --chown=www-data:www-data . .

# Install OJS specific dependencies
RUN composer --working-dir=lib/pkp install --no-dev --optimize-autoloader --no-interaction \
    && composer --working-dir=plugins/generic/citationStyleLanguage install --no-dev --optimize-autoloader --no-interaction \
    && composer --working-dir=plugins/paymethod/paypal install --no-dev --optimize-autoloader --no-interaction \
    && npm install \
    && npm run build \
    && npm cache clean --force

# Create directories and set permissions
RUN mkdir -p storage/tmp \
    && chown -R www-data:www-data storage cache public \
    && chmod -R 755 storage cache \
    && if [ -f config.inc.php ]; then chmod 644 config.inc.php; fi

# Configure PHP
RUN echo "upload_max_filesize = 100M" >> /usr/local/etc/php/conf.d/uploads.ini \
    && echo "post_max_size = 100M" >> /usr/local/etc/php/conf.d/uploads.ini \
    && echo "max_execution_time = 300" >> /usr/local/etc/php/conf.d/uploads.ini \
    && echo "memory_limit = 512M" >> /usr/local/etc/php/conf.d/uploads.ini

# Configure Nginx
COPY docker/nginx.conf /etc/nginx/nginx.conf
COPY docker/default.conf /etc/nginx/conf.d/default.conf

# Configure Supervisor
COPY docker/supervisord.conf /etc/supervisor/supervisord.conf

# Create entrypoint script
COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000/ || exit 1

CMD ["/entrypoint.sh"]