# syntax=docker/dockerfile:1.4
FROM us-west2-docker.pkg.dev/shepherd-268822/shepherd2/concourse-resource:latest as shepherd

FROM alpine:3.18 as builder

# Version arguments with defaults
ARG CREDHUB_VERSION=""
ARG BOSH_VERSION=""
ARG BBL_VERSION=""

# Install build dependencies
RUN apk add --no-cache \
    curl \
    jq \
    wget \
    tar \
    ca-certificates

# Download and prepare binaries
RUN set -eux; \
    # Set versions to latest if not provided
    [ -n "$CREDHUB_VERSION" ] || CREDHUB_VERSION=$(curl -s https://api.github.com/repos/cloudfoundry/credhub-cli/releases/latest | jq -r .tag_name) && \
    [ -n "$BOSH_VERSION" ] || BOSH_VERSION=$(curl -s https://api.github.com/repos/cloudfoundry/bosh-cli/releases/latest | jq -r .tag_name[1:]) && \
    [ -n "$BBL_VERSION" ] || BBL_VERSION=$(curl -s https://api.github.com/repos/cloudfoundry/bosh-bootloader/releases/latest | jq -r '.tag_name[1:]') && \
    # Download and extract Credhub CLI
    wget -q "https://github.com/cloudfoundry/credhub-cli/releases/download/${CREDHUB_VERSION}/credhub-linux-amd64-${CREDHUB_VERSION}.tgz" && \
    tar xzf "credhub-linux-amd64-${CREDHUB_VERSION}.tgz" && \
    mv credhub /usr/local/bin/ && \
    # Download BOSH CLI
    wget -q "https://github.com/cloudfoundry/bosh-cli/releases/download/v${BOSH_VERSION}/bosh-cli-${BOSH_VERSION}-linux-amd64" -O /usr/local/bin/bosh && \
    chmod +x /usr/local/bin/bosh && \
    # Download BBL CLI
    wget -q "https://github.com/cloudfoundry/bosh-bootloader/releases/download/v${BBL_VERSION}/bbl-v${BBL_VERSION}_linux_amd64" -O /usr/local/bin/bbl && \
    chmod +x /usr/local/bin/bbl

FROM alpine:3.18

LABEL maintainer="Stack Auditor Team" \
      description="Base image for Stack Auditor with CF CLI and related tools" \
      version="1.0"

# Create non-root user
RUN addgroup -S stackauditor && \
    adduser -S -G stackauditor stackauditor

# Install runtime dependencies
RUN apk add --no-cache \
    python3 \
    py3-pip \
    curl \
    jq \
    wget \
    tar \
    bash \
    ca-certificates

# Install CF CLI
RUN wget -q -O cf.tgz "https://packages.cloudfoundry.org/stable?release=linux64-binary&version=v8&source=github" && \
    tar xzf cf.tgz && \
    mv cf8 /usr/local/bin/cf && \
    rm -f cf.tgz

# Copy binaries from builder stages
COPY --from=builder /usr/local/bin/credhub /usr/local/bin/bosh /usr/local/bin/bbl /usr/local/bin/
COPY --from=shepherd /usr/local/bin/shepherd /usr/local/bin/

# Set permissions
RUN chmod +x /usr/local/bin/shepherd && \
    chown -R stackauditor:stackauditor \
        /usr/local/bin/credhub \
        /usr/local/bin/bosh \
        /usr/local/bin/bbl \
        /usr/local/bin/shepherd \
        /usr/local/bin/cf

# Switch to non-root user
USER stackauditor

# Health check
HEALTHCHECK --interval=30s --timeout=3s \
    CMD cf version && shepherd version || exit 1

# Verify all tools are working
RUN cf version && \
    credhub --version && \
    bosh --version && \
    bbl --version && \
    shepherd version
