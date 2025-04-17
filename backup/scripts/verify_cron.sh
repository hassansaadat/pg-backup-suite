#!/bin/bash

set -e

schedule=$VERIFY_CRON # every Friday midnight at 12:00:00

echo "Setting up backup verifier at schedule: $schedule"

# Create crontab entry
echo "$schedule /app/scripts/verify.sh" >> /app/logs/verify.log 2>&1 >> /etc/crontabs/root

# Start cron in foreground
crond -f
