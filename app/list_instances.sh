#!/bin/bash
# list_instances.sh - Shows all active demos and how long they've been running.

TRACKER_DIR="/opt/app/instance_tracker"

echo "--- Active Demo Instances ---"
# 'ls -t' lists files by modification time, newest first.
ls -t "$TRACKER_DIR" | while read -r instance_name; do
    # Get the file's modification date
    mod_time=$(stat -c %y "$TRACKER_DIR/$instance_name")
    echo "Instance: ${instance_name} | Created: ${mod_time}"
done
echo "---------------------------"