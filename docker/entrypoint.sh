#!/bin/sh
set -e

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

# Set proper permissions
chown -R www-data:www-data storage cache public
chmod -R 755 storage cache

# Start supervisor
exec /usr/bin/supervisord -c /etc/supervisor/supervisord.conf