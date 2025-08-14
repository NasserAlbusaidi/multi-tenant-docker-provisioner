#!/bin/bash
# extend_instance.sh - Resets the clock for a given demo instance.

INSTANCE_ID="$1"
TRACKER_FILE="/opt/app/instance_tracker/${INSTANCE_ID}"

if [ -f "$TRACKER_FILE" ]; then
    touch "$TRACKER_FILE"
    echo "Success! The lifetime for instance '$INSTANCE_ID' has been reset."
else
    echo "Error: Instance '$INSTANCE_ID' not found."
fi