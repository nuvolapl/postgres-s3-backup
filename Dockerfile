ARG POSTGRES_VERSION=18

FROM postgres:${POSTGRES_VERSION}-alpine

LABEL org.opencontainers.image.source="https://github.com/nuvolapl/postgres-s3-backup"
LABEL org.opencontainers.image.description="PostgreSQL backup to S3-compatible storage"
LABEL org.opencontainers.image.vendor="Nuvola (https://www.nuvola.pl)"
LABEL org.opencontainers.image.license="MIT"

RUN apk add --no-cache aws-cli

COPY entrypoint.sh backup.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/backup.sh

USER root

ENTRYPOINT ["entrypoint.sh"]
