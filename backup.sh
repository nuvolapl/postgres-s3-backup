#!/bin/sh
set -eu

POSTGRES_PORT="${POSTGRES_PORT:-5432}"
# No colon: an explicitly empty value disables the default flags
PGDUMP_EXTRA_ARGS="${PGDUMP_EXTRA_ARGS---no-owner --no-acl}"
S3_PREFIX="${S3_PREFIX:-}"
S3_PREFIX="${S3_PREFIX%/}"

log() { echo "$(date -u '+%Y-%m-%d %H:%M:%S') $*"; }

FILENAME="${POSTGRES_DB}-$(date -u +%Y%m%d-%H%M%S).dump"
S3_KEY="${S3_PREFIX:+${S3_PREFIX}/}${FILENAME}"
TMPFILE="$(mktemp)"
trap 'rm -f "$TMPFILE"' EXIT

export PGPASSWORD="$POSTGRES_PASSWORD"
export AWS_ACCESS_KEY_ID="$S3_ACCESS_KEY_ID"
export AWS_SECRET_ACCESS_KEY="$S3_SECRET_ACCESS_KEY"
export AWS_DEFAULT_REGION="${S3_REGION:-${AWS_DEFAULT_REGION:-us-east-1}}"
# Many S3-compatible backends reject the CLI's default request checksums
export AWS_REQUEST_CHECKSUM_CALCULATION=WHEN_REQUIRED
export AWS_RESPONSE_CHECKSUM_VALIDATION=WHEN_REQUIRED

log "Backing up ${POSTGRES_DB}@${POSTGRES_HOST}:${POSTGRES_PORT}..."

# shellcheck disable=SC2086
pg_dump -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" \
  --format=custom \
  --lock-wait-timeout=300000 \
  --quote-all-identifiers \
  $PGDUMP_EXTRA_ARGS \
  --file="$TMPFILE" \
  "$POSTGRES_DB"

aws s3api put-object \
  --bucket "$S3_BUCKET" \
  --key "$S3_KEY" \
  --body "$TMPFILE" \
  ${S3_ENDPOINT:+--endpoint-url "$S3_ENDPOINT"} > /dev/null

log "Backup complete: s3://${S3_BUCKET}/${S3_KEY} ($(du -h "$TMPFILE" | cut -f1))"
