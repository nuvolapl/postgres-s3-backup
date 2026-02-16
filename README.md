# postgres-s3-backup

[![Build and Push](https://github.com/nuvolapl/postgres-s3-backup/actions/workflows/build-postgres-s3-backup.yml/badge.svg)](https://github.com/nuvolapl/postgres-s3-backup/actions/workflows/build-postgres-s3-backup.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

Lightweight Docker image for PostgreSQL backups to S3-compatible storage.

Runs `pg_dump` in custom format on a cron schedule and uploads to S3. Built on the official `postgres`-alpine image so `pg_dump` always matches your server version.

Supports any S3-compatible backend: AWS S3, OCI Object Storage, MinIO, Cloudflare R2, and more.

## Quick start

```yaml
services:
  postgres-s3-backup:
    image: ghcr.io/nuvolapl/postgres-s3-backup:18
    environment:
      POSTGRES_HOST: postgres
      POSTGRES_USER: myuser
      POSTGRES_PASSWORD: mypassword
      POSTGRES_DB: mydb
      S3_BUCKET: my-backups
      S3_ACCESS_KEY_ID: AKIA...
      S3_SECRET_ACCESS_KEY: secret
      S3_ENDPOINT: https://s3.amazonaws.com   # optional, for S3-compatible services
      S3_PREFIX: daily                        # optional, folder in bucket
      SCHEDULE: "0 3 * * *"                   # optional, default: daily at 3 AM UTC
      BACKUP_ON_START: "true"                 # optional, run backup immediately on start
    depends_on:
      postgres:
        condition: service_healthy
    restart: unless-stopped
```

## Image tags

Tags follow the same convention as the [official PostgreSQL image](https://hub.docker.com/_/postgres) — the tag is the PostgreSQL major version:

| Tag | PostgreSQL version | Base image |
|-----|--------------------|------------|
| `18`, `18-alpine`, `latest` | 18 | `postgres:18-alpine` |
| `17`, `17-alpine` | 17 | `postgres:17-alpine` |
| `16`, `16-alpine` | 16 | `postgres:16-alpine` |

Pick the tag matching your PostgreSQL server version so that `pg_dump` is compatible.

Multi-arch images are published for `linux/amd64` and `linux/arm64`.

## Environment variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `POSTGRES_HOST` | Yes | | Database hostname |
| `POSTGRES_PORT` | No | `5432` | Database port |
| `POSTGRES_USER` | Yes | | Database user |
| `POSTGRES_PASSWORD` | Yes | | Database password |
| `POSTGRES_DB` | Yes | | Database name |
| `S3_BUCKET` | Yes | | S3 bucket name |
| `S3_ACCESS_KEY_ID` | Yes | | S3 access key |
| `S3_SECRET_ACCESS_KEY` | Yes | | S3 secret key |
| `S3_ENDPOINT` | No | | Custom S3 endpoint URL |
| `S3_PREFIX` | No | | Path prefix (folder) in bucket |
| `SCHEDULE` | No | `0 3 * * *` | Cron expression (UTC) |
| `BACKUP_ON_START` | No | `false` | Run a backup immediately on container start |
| `PGDUMP_EXTRA_ARGS` | No | `--no-owner --no-acl` | Additional `pg_dump` arguments |

## Backup format

Backups use PostgreSQL custom format (`-Fc`) which provides built-in compression, parallel restore, and selective restore capabilities.

Files are stored as:

```
{S3_PREFIX/}{POSTGRES_DB}-{YYYYMMDD-HHMMSS}.dump
```

By default, backups exclude ownership (`--no-owner`) and privilege (`--no-acl`) information for portability. To keep them, set `PGDUMP_EXTRA_ARGS` to an empty string or your own flags:

```yaml
PGDUMP_EXTRA_ARGS: ""              # keep ownership and privileges
PGDUMP_EXTRA_ARGS: "--no-owner"    # drop ownership only
```

## Restore

```bash
# Download
aws s3 cp s3://my-backups/daily/mydb-20260216-030000.dump /tmp/backup.dump \
  --endpoint-url https://s3.amazonaws.com

# Restore
docker exec -i postgres pg_restore -U myuser -d mydb < /tmp/backup.dump

# Restore a single table
docker exec -i postgres pg_restore -U myuser -d mydb -t my_table < /tmp/backup.dump
```

## Contributing

Contributions are welcome! Please open an issue or submit a pull request.

## License

This project is licensed under the [MIT License](LICENSE).

---

Maintained by [Nuvola](https://www.nuvola.pl)
