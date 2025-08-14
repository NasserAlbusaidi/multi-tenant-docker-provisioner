#!/bin/bash
# setup_instance_multi_domain.sh - Deployment creating a unique subdomain per instance

set -e

if [ -z "$1" ]; then
  echo "Error: Missing INSTANCE_ID."
  exit 1
fi

INSTANCE_ID="$1"
APP_IMAGE="[YOUR_APP_IMAGE]"
MYSQL_IMAGE="mysql:8.0"
BASE_DOMAIN="[YOUR_BASE_DOMAIN]"

MYSQL_CONTAINER_NAME="instance-${INSTANCE_ID}-mysql"
APP_CONTAINER_NAME="instance-${INSTANCE_ID}-app"
MYSQL_VOLUME_NAME="instance-${INSTANCE_ID}-mysql-data"
NETWORK_NAME="traefik-proxy" 
INSTANCE_NETWORK="instance-${INSTANCE_ID}-net"

# CHANGED: The domain and URL are now dynamic based on the INSTANCE_ID
INSTANCE_DOMAIN="${INSTANCE_ID}.${BASE_DOMAIN}"
PUBLIC_URL="https://${INSTANCE_DOMAIN}"

log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [$INSTANCE_ID] $1"; }

# Check if the public-facing network exists, if not create it.
docker network inspect $NETWORK_NAME >/dev/null 2>&1 || docker network create $NETWORK_NAME

# Create a dedicated private network for the instance
log "Creating private network: $INSTANCE_NETWORK"
docker network create "$INSTANCE_NETWORK"

MYSQL_ROOT_PASSWORD=$(openssl rand -hex 16)
DB_NAME="agm_${INSTANCE_ID}"
DB_USER="user_${INSTANCE_ID}"
DB_PASS=$(openssl rand -hex 16)

# --- Start MySQL ---
log "Starting MySQL container..."
docker run -d \
  --network "$INSTANCE_NETWORK" \
  --name "$MYSQL_CONTAINER_NAME" \
  -e MYSQL_ROOT_PASSWORD="$MYSQL_ROOT_PASSWORD" \
  -e MYSQL_DATABASE="$DB_NAME" \
  -e MYSQL_USER="$DB_USER" \
  -e MYSQL_PASSWORD="$DB_PASS" \
  -v "$MYSQL_VOLUME_NAME:/var/lib/mysql" \
  --restart always \
  "$MYSQL_IMAGE"

# --- Wait for MySQL ---
log "Waiting for MySQL to be ready..."
for i in {1..30}; do
  if docker exec "$MYSQL_CONTAINER_NAME" mysql --user="$DB_USER" --password="$DB_PASS" --host="localhost" --database="$DB_NAME" -e "SELECT 1;" > /dev/null 2>&1; then
    log "MySQL is ready and database is accessible!"
    break
  fi
  log "Database not ready yet. Retrying in 2 seconds... ($i/30)"
  sleep 2
done

# --- Start App ---
log "Starting AGM App for ${PUBLIC_URL}"

# The Host rule for Traefik now uses the dynamic INSTANCE_DOMAIN
docker run -d \
  --network "$NETWORK_NAME" \
  --network "$INSTANCE_NETWORK" \
  --name "$APP_CONTAINER_NAME" \
  -e DB_CONNECTION=mysql \
  -e DB_HOST="$MYSQL_CONTAINER_NAME" \
  -e DB_DATABASE="$DB_NAME" \
  -e DB_USERNAME="$DB_USER" \
  -e DB_PASSWORD="$DB_PASS" \
  -e FORCE_HTTPS="true" \
  -e APP_URL="$PUBLIC_URL" \
  --restart always \
  --label "traefik.enable=true" \
  --label "traefik.http.routers.${APP_CONTAINER_NAME}.rule=Host(\`${INSTANCE_DOMAIN}\`)" \
  --label "traefik.http.routers.${APP_CONTAINER_NAME}.entrypoints=web" \
  --label "traefik.http.services.${APP_CONTAINER_NAME}.loadbalancer.server.port=80" \
  --label "traefik.docker.network=${NETWORK_NAME}" \
  "$APP_IMAGE"

log "Instance running at $PUBLIC_URL"

touch "/opt/app/instance_tracker/${INSTANCE_ID}"
log "Created timestamp file for automatic cleanup."


# --- Output ---
cat <<EOF
---INSTANCE_DATA_START---
{
  "status": "success",
  "instance_id": "$INSTANCE_ID",
  "url": "$PUBLIC_URL",
  "db_name": "$DB_NAME",
  "db_user": "$DB_USER",
  "db_pass": "$DB_PASS"
}
---INSTANCE_DATA_END---
EOF