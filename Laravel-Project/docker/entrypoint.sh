#!/bin/sh
set -e

# Change to the project directory
cd /var/www/[app-name]

# --- Wait for Database Connection ---
echo "Waiting for database to be ready..."
# This loop will try to connect to the database using a simple PHP command.
# It will keep trying every 2 seconds until it succeeds.
# The > /dev/null 2>&1 suppresses error messages from flooding the logs.
until php -r "new PDO(\"mysql:host=$DB_HOST;port=3306\", \"$DB_USERNAME\", \"$DB_PASSWORD\");" > /dev/null 2>&1; do
    echo "Database is not ready yet. Retrying in 2 seconds..."
    sleep 2
done
echo "Database is up and running!"
# --- End Wait for Database ---


# If .env doesn't exist, create it from the example
if [ ! -f ".env" ]; then
    echo "Creating .env file from example..."
    cp .env.example .env
    # Generate the app key on the very first run
    php artisan key:generate
fi

echo "Caching configuration and routes..."
php artisan config:cache
php artisan route:cache

# Run database migrations
echo "Running database migrations..."
php artisan migrate --force


# Optimize the application for production
echo "Caching configuration and routes..."
php artisan optimize

# Set correct permissions on the storage path
chown -R www-data:www-data /var/www/[app-name]/storage /var/www/[app-name]/bootstrap/cache

echo "Application setup complete. Starting services..."

# Execute the main command (CMD) from the Dockerfile (which is supervisord)
exec "$@"
