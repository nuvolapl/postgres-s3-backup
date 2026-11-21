ARG POSTGRES_VERSION=19
ARG ALPINE_VERSION=3.24

FROM postgres:${POSTGRES_VERSION}-alpine${ALPINE_VERSION}

LABEL org.opencontainers.image.source="https://github.com/nuvolapl/postgres-s3-backup"
LABEL org.opencontainers.image.description="PostgreSQL backup to S3-compatible storage"
LABEL org.opencontainers.image.vendor="Nuvola (https://www.nuvola.pl)"
LABEL org.opencontainers.image.licenses="MIT"

RUN apk add --no-cache aws-cli

COPY --chmod=755 entrypoint.sh backup.sh /usr/local/bin/

ENTRYPOINT ["entrypoint.sh"]
