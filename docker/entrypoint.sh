#!/bin/sh
set -e

# Set default values for environment variables
export APP_URL="${APP_URL:-http://localhost}"
export DB_HOST="${DB_HOST:-db}"
export DB_PORT="${DB_PORT:-3306}"
export DB_USER="${DB_USER:-ojs}"
export DB_PASSWORD="${DB_PASSWORD:-ojs_password}"
export DB_DATABASE="${DB_DATABASE:-ojs}"

# Email configuration with defaults
export SMTP_METHOD="${SMTP_METHOD:-log}"
export SMTP_HOST="${SMTP_HOST:-localhost}"
export SMTP_PORT="${SMTP_PORT:-25}"
export SMTP_AUTH="${SMTP_AUTH:-Off}"
export SMTP_USERNAME="${SMTP_USERNAME:-}"
export SMTP_PASSWORD="${SMTP_PASSWORD:-}"
export SMTP_ENCRYPTION="${SMTP_ENCRYPTION:-none}"

# Create config.inc.php with environment variables (persistent volume friendly)
CONFIG_PATH="/var/www/html/config.inc.php"
PERSISTENT_CONFIG_PATH="/var/www/html/storage/config.inc.php"

# Check if persistent config exists
if [ -f "$PERSISTENT_CONFIG_PATH" ]; then
    echo "Using existing persistent configuration..."
    cp "$PERSISTENT_CONFIG_PATH" "$CONFIG_PATH"
elif [ ! -f "$CONFIG_PATH" ]; then
    echo "Creating new configuration from environment variables..."
    # Generate config with environment substitution
    envsubst < /var/www/html/docker/config.docker.inc.php > "$CONFIG_PATH"
    # Save to persistent location
    cp "$CONFIG_PATH" "$PERSISTENT_CONFIG_PATH"
    echo "Configuration created and saved to persistent storage"
else
    echo "Configuration already exists, updating from persistent storage if available"
    if [ -f "$PERSISTENT_CONFIG_PATH" ]; then
        cp "$PERSISTENT_CONFIG_PATH" "$CONFIG_PATH"
    fi
fi

chmod 644 "$CONFIG_PATH"

# Wait for database
echo "Waiting for database..."
until php -r "
try {
    \$pdo = new PDO('mysql:host='.getenv('DB_HOST').';port='.getenv('DB_PORT'), getenv('DB_USER'), getenv('DB_PASSWORD'));
    exit(0);
} catch (Exception \$e) {
    exit(1);
}"; do
    echo "Database not ready, waiting..."
    sleep 2
done

echo "Database is ready!"

# Create necessary directories
mkdir -p /var/log/supervisor
mkdir -p /var/log/nginx
mkdir -p storage/logs
mkdir -p storage/tmp
mkdir -p storage/review
mkdir -p public

# Set proper permissions
chown -R www-data:www-data storage cache public config.inc.php
chmod -R 755 storage cache public
chmod 644 config.inc.php

# Start supervisor
exec /usr/bin/supervisord -c /etc/supervisor/supervisord.conf