#!/bin/sh
set -e

POSTGRES_PORT="${POSTGRES_PORT:-5432}"
S3_PREFIX="${S3_PREFIX:-}"
PGDUMP_EXTRA_ARGS="${PGDUMP_EXTRA_ARGS:---no-owner --no-acl}"

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
FILENAME="${POSTGRES_DB}-${TIMESTAMP}.dump"
TMPFILE="/tmp/${FILENAME}"

if [ -n "$S3_PREFIX" ]; then
  S3_KEY="${S3_PREFIX}/${FILENAME}"
else
  S3_KEY="${FILENAME}"
fi

export PGPASSWORD="$POSTGRES_PASSWORD"
export AWS_ACCESS_KEY_ID="$S3_ACCESS_KEY_ID"
export AWS_SECRET_ACCESS_KEY="$S3_SECRET_ACCESS_KEY"

ENDPOINT_ARG=""
if [ -n "${S3_ENDPOINT:-}" ]; then
  ENDPOINT_ARG="--endpoint-url ${S3_ENDPOINT}"
fi

cleanup() { rm -f "$TMPFILE"; }
trap cleanup EXIT

echo "$(date '+%Y-%m-%d %H:%M:%S') Backing up ${POSTGRES_DB}@${POSTGRES_HOST}:${POSTGRES_PORT}..."

pg_dump -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" \
  --format=custom \
  --lock-wait-timeout=300000 \
  --quote-all-identifiers \
  $PGDUMP_EXTRA_ARGS \
  "$POSTGRES_DB" > "$TMPFILE"

aws s3api put-object \
  --bucket "$S3_BUCKET" \
  --key "$S3_KEY" \
  --body "$TMPFILE" \
  $ENDPOINT_ARG > /dev/null

echo "$(date '+%Y-%m-%d %H:%M:%S') Backup complete: s3://${S3_BUCKET}/${S3_KEY}"
