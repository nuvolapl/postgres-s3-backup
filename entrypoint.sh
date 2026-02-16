#!/bin/sh
set -e

: "${POSTGRES_HOST:?POSTGRES_HOST is required}"
: "${POSTGRES_USER:?POSTGRES_USER is required}"
: "${POSTGRES_PASSWORD:?POSTGRES_PASSWORD is required}"
: "${POSTGRES_DB:?POSTGRES_DB is required}"
: "${S3_BUCKET:?S3_BUCKET is required}"
: "${S3_ACCESS_KEY_ID:?S3_ACCESS_KEY_ID is required}"
: "${S3_SECRET_ACCESS_KEY:?S3_SECRET_ACCESS_KEY is required}"

SCHEDULE="${SCHEDULE:-0 3 * * *}"

# Persist backup-related env vars for cron (cron doesn't inherit container env)
printenv | grep -E '^(POSTGRES_|S3_|SCHEDULE|BACKUP_ON_START|PGDUMP_EXTRA_ARGS)' > /etc/backup.env

# Set up cron job
echo "${SCHEDULE} . /etc/backup.env; /usr/local/bin/backup.sh >> /proc/1/fd/1 2>&1" | crontab -

echo "postgres-s3-backup: scheduled '${SCHEDULE}' for ${POSTGRES_DB}@${POSTGRES_HOST}"

if [ "${BACKUP_ON_START:-}" = "true" ]; then
  /usr/local/bin/backup.sh
fi

exec crond -f -l 2
