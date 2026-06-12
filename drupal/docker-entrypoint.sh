#!/bin/sh
set -e

# ------------------------------------------------------------------------------
# Production Drupal Entrypoint
# Handles pre-flight checks, permission hardening, and bootstrapping.
# ------------------------------------------------------------------------------

echo "[drupal-entrypoint] Starting production Drupal container..."

# Wait for the database to be ready (simple TCP check)
if [ -n "$DB_HOST" ]; then
    DB_PORT="${DB_PORT:-3306}"
    echo "[drupal-entrypoint] Waiting for database at $DB_HOST:$DB_PORT..."
    until nc -z -v -w30 "$DB_HOST" "$DB_PORT" 2>/dev/null; do
        echo "[drupal-entrypoint] Database not ready yet. Retrying in 2s..."
        sleep 2
    done
    echo "[drupal-entrypoint] Database connection established."
fi

# Ensure essential directories exist and have correct ownership
mkdir -p /var/www/html/web/sites/default/files
mkdir -p /var/www/html/web/sites/default/private
mkdir -p /var/www/html/config/sync

# Writable paths for the web server process
chown -R www-data:www-data /var/www/html/web/sites/default/files
chown -R www-data:www-data /var/www/html/web/sites/default/private
chmod -R 775 /var/www/html/web/sites/default/files
chmod 750 /var/www/html/web/sites/default/private

# Enable/disable maintenance mode based on DRUPAL_MAINTENANCE_MODE env var
if [ "$DRUPAL_MAINTENANCE_MODE" = "true" ]; then
    echo "[drupal-entrypoint] Maintenance mode enabled."
else
    echo "[drupal-entrypoint] Maintenance mode disabled."
fi

echo "[drupal-entrypoint] Handing off to Apache..."
exec "$@"
