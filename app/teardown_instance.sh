#!/bin/bash
# teardown_instance.sh - Removes all resources for a given instance ID

set -e

if [ -z "$1" ]; then
  echo "Error: Missing INSTANCE_ID."
  exit 1
fi

INSTANCE_ID="$1"
MYSQL_CONTAINER_NAME="instance-${INSTANCE_ID}-mysql"
APP_CONTAINER_NAME="instance-${INSTANCE_ID}-app"
MYSQL_VOLUME_NAME="instance-${INSTANCE_ID}-mysql-data"
INSTANCE_NETWORK="instance-${INSTANCE_ID}-net"

echo "[$(date)] Tearing down instance: $INSTANCE_ID"

# Use || true to prevent the script from failing if a resource is already gone
echo "[$(date)] Removing containers..."
docker rm -f "$APP_CONTAINER_NAME" "$MYSQL_CONTAINER_NAME" > /dev/null 2>&1 || true

echo "[$(date)] Removing network..."
docker network rm "$INSTANCE_NETWORK" > /dev/null 2>&1 || true

echo "[$(date)] Removing volume..."
docker volume rm "$MYSQL_VOLUME_NAME" > /dev/null 2>&1 || true

echo "[$(date)] Cleanup for $INSTANCE_ID complete."