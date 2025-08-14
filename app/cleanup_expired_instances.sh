#!/bin/bash
# cleanup_expired_instances.sh - Finds and destroys demo instances older than a set time.

# --- Configuration for Testing ---
TRACKER_DIR="/opt/app/instance_tracker"
TEARDOWN_SCRIPT="/opt/app/teardown_instance.sh"
MAX_LIFETIME_MINUTES=5 # Set to 5 minutes for easy testing! Change to 1440 (24h) for prod.

# --- Main Logic ---
echo "[$(date)] --- Starting Cleanup Job ---"
find "$TRACKER_DIR" -type f -mmin "+${MAX_LIFETIME_MINUTES}" | while read -r expired_file; do
    INSTANCE_ID=$(basename "$expired_file")
    echo "[$(date)] Found expired instance: '$INSTANCE_ID'. Initiating teardown."
    "$TEARDOWN_SCRIPT" "$INSTANCE_ID" || true
    rm -f "$expired_file"
    echo "[$(date)] Teardown for '$INSTANCE_ID' complete and tracker file removed."
done
echo "[$(date)] --- Cleanup Job Finished ---"