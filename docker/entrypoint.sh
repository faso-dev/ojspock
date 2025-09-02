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

# Check if config.inc.php is a directory (can happen with volume mounting issues)
if [ -d "$CONFIG_PATH" ]; then
    echo "WARNING: config.inc.php is a directory, removing it..."
    rm -rf "$CONFIG_PATH"
fi

# Check if config.inc.php exists but is not writable (volume mount issue)
if [ -f "$CONFIG_PATH" ] && [ ! -w "$CONFIG_PATH" ]; then
    echo "WARNING: config.inc.php exists but is not writable, creating backup and replacing..."
    cp "$CONFIG_PATH" "$CONFIG_PATH.backup" 2>/dev/null || true
    rm -f "$CONFIG_PATH"
fi

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

# Always ensure the persistent config is up to date with current config
# This handles cases where config was modified through OJS interface
if [ -f "$CONFIG_PATH" ] && [ -f "$PERSISTENT_CONFIG_PATH" ]; then
    # Compare timestamps and update persistent config if current is newer
    if [ "$CONFIG_PATH" -nt "$PERSISTENT_CONFIG_PATH" ]; then
        echo "Updating persistent configuration with current changes..."
        cp "$CONFIG_PATH" "$PERSISTENT_CONFIG_PATH"
    fi
elif [ -f "$CONFIG_PATH" ] && [ ! -f "$PERSISTENT_CONFIG_PATH" ]; then
    # If we have a config but no persistent version, save it
    echo "Saving current configuration to persistent storage..."
    cp "$CONFIG_PATH" "$PERSISTENT_CONFIG_PATH"
fi

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

# Check if OJS is installed (check if versions table exists)
echo "Checking if OJS is installed..."
OJS_INSTALLED=$(php -r "
try {
    \$pdo = new PDO('mysql:host='.getenv('DB_HOST').';port='.getenv('DB_PORT').';dbname='.getenv('DB_DATABASE'), getenv('DB_USER'), getenv('DB_PASSWORD'));
    \$stmt = \$pdo->query('SHOW TABLES LIKE \"versions\"');
    if (\$stmt->rowCount() == 0) {
        echo 'no';
    } else {
        echo 'yes';
    }
} catch (Exception \$e) {
    echo 'no';
}
")

if [ "$OJS_INSTALLED" = "yes" ]; then
    echo "OJS is already installed, skipping installation"
else
    echo "OJS not found, starting automatic installation..."
    
    # Use the built-in OJS installation tool
    echo "Running OJS installation via tools/install.php..."
    
    # Create a simple installation script that uses the CLI tool
    cat > /tmp/auto_install.sh << 'EOF'
#!/bin/bash
cd /var/www/html

# Create a response file for the installation
cat > /tmp/install_responses.txt << 'RESPONSES'
en
storage
admin
admin123
admin123
admin@ojs.onassgroupe.com
mysql
db
ojs
ojs_password
ojs
ojs.onassgroupe.com
Y
Y
RESPONSES

# Run the installation with the responses
php tools/install.php < /tmp/install_responses.txt

if [ $? -eq 0 ]; then
    echo "OJS installation completed successfully!"
    echo "Admin credentials:"
    echo "  Username: admin"
    echo "  Password: admin123"
    echo "  Email: admin@ojs.onassgroupe.com"
    echo "⚠️  IMPORTANT: Change these credentials after first login!"
else
    echo "OJS installation failed. You may need to install manually:"
    echo "1. Visit https://ojs.onassgroupe.com"
    echo "2. Or run: php tools/install.php in the container terminal"
fi
EOF

    chmod +x /tmp/auto_install.sh
    /tmp/auto_install.sh
fi

# Create necessary directories
mkdir -p /var/log/supervisor
mkdir -p /var/log/nginx
mkdir -p storage/logs
mkdir -p storage/tmp
mkdir -p storage/review
mkdir -p public
mkdir -p /var/lib/php/session
mkdir -p /var/lib/php/wsdlcache

# Set proper permissions
chown -R www-data:www-data storage cache public /var/lib/php
chmod -R 755 storage cache public
chmod -R 755 /var/lib/php

# Set permissions for config.inc.php if it exists
if [ -f "$CONFIG_PATH" ]; then
    chown www-data:www-data "$CONFIG_PATH"
    chmod 644 "$CONFIG_PATH"
fi

# Create a script to backup config changes
cat > /usr/local/bin/backup-config.sh << 'EOF'
#!/bin/sh
# Backup current config to persistent storage
if [ -f "/var/www/html/config.inc.php" ]; then
    cp "/var/www/html/config.inc.php" "/var/www/html/storage/config.inc.php"
    echo "$(date): Configuration backed up to persistent storage"
fi
EOF
chmod +x /usr/local/bin/backup-config.sh

# Test PHP-FPM configuration
echo "Testing PHP-FPM configuration..."
php-fpm --test --fpm-config /usr/local/etc/php-fpm.d/www.conf

# Start PHP-FPM first
echo "Starting PHP-FPM..."
php-fpm --fpm-config /usr/local/etc/php-fpm.d/www.conf &
PHP_FPM_PID=$!

# Wait for PHP-FPM socket to be created
echo "Waiting for PHP-FPM socket..."
for i in $(seq 1 30); do
    if [ -S /var/run/php-fpm.sock ]; then
        echo "PHP-FPM socket created successfully"
        break
    fi
    echo "Waiting for PHP-FPM socket... ($i/30)"
    sleep 1
done

# Test nginx configuration
echo "Testing nginx configuration..."
nginx -t

# Start nginx
echo "Starting nginx..."
nginx -g 'daemon off;'