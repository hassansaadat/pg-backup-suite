ARG POSTGRES_VERSION=17-alpine
FROM postgres:${POSTGRES_VERSION}

# Install required tools
RUN apk update && \
    apk add --no-cache \
    bash \
    gnupg \
    curl \
    dcron \
    libc6-compat \
    unzip

# Install MinIO client (mc)
RUN curl -O https://dl.min.io/client/mc/release/linux-amd64/mc && \
    install mc /usr/local/bin/mc && \
    rm mc

# Set working directory
WORKDIR /app

COPY backup/scripts /app/scripts

RUN chmod +x /app/scripts/*.sh

RUN mkdir -p /app/logs /app/local_backups && \
    chown -R 1000:1000 /app/logs /app/local_backups
