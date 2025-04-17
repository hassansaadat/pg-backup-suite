#!/bin/bash

set -e

i=1

while true; do
    var_name="DB${i}_NAME"
    db_name="${!var_name}"

    var_name="DB${i}_CRON"
    db_cron="${!var_name}"

    var_name="DB${i}_USER"
    db_user="${!var_name}"

    var_name="DB${i}_PASSWORD"
    db_password="${!var_name}"

    var_name="DB${i}_HOST"
    db_host="${!var_name}"

    var_name="DB${i}_PORT"
    db_port="${!var_name}"

    if [ -z "$db_name" ]; then
        break
    fi

    echo "Setting up backup for DB $db_name at schedule: $db_cron"

    # Write full credentials into the cron job
    echo "$db_cron /app/scripts/backup.sh \"$db_name\" \"$db_user\" \"$db_password\" \"$db_host\" \"$db_port\" >> /app/logs/backup-${db_name}.log 2>&1" >> /etc/crontabs/root

    i=$((i + 1))
done

# Start cron in foreground mode
crond -f
