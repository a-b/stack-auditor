# syntax=docker/dockerfile:1.4
FROM us-west2-docker.pkg.dev/shepherd-268822/shepherd2/concourse-resource:latest as shepherd

FROM alpine:3.20.3 as builder

ARG CREDHUB_VERSION=""
ARG BOSH_VERSION=""
ARG BBL_VERSION=""
ARG CF_VERSION=""

RUN apk add --no-cache \
    curl \
    jq \
    wget \
    tar \
    ca-certificates

RUN set -eux; \
    [ -n "$CREDHUB_VERSION" ] || CREDHUB_VERSION=$(curl -s https://api.github.com/repos/cloudfoundry/credhub-cli/releases/latest | jq -r .tag_name) && \
    [ -n "$BOSH_VERSION" ] || BOSH_VERSION=$(curl -s https://api.github.com/repos/cloudfoundry/bosh-cli/releases/latest | jq -r '.tag_name[1:]') && \
    [ -n "$BBL_VERSION" ] || BBL_VERSION=$(curl -s https://api.github.com/repos/cloudfoundry/bosh-bootloader/releases/latest | jq -r '.tag_name[1:]') && \
    [ -n "$CF_VERSION" ] || CF_VERSION=$(curl -s https://api.github.com/repos/cloudfoundry/cli/releases/latest | jq -r '.tag_name' | tr -d 'v') && \
    wget -q "https://github.com/cloudfoundry/credhub-cli/releases/download/${CREDHUB_VERSION}/credhub-linux-amd64-${CREDHUB_VERSION}.tgz" && \
    tar xzf "credhub-linux-amd64-${CREDHUB_VERSION}.tgz" && \
    mv credhub /usr/local/bin/ && \
    wget -q "https://github.com/cloudfoundry/bosh-cli/releases/download/v${BOSH_VERSION}/bosh-cli-${BOSH_VERSION}-linux-amd64" -O /usr/local/bin/bosh && \
    chmod +x /usr/local/bin/bosh && \
    wget -q "https://github.com/cloudfoundry/bosh-bootloader/releases/download/v${BBL_VERSION}/bbl-v${BBL_VERSION}_linux_amd64" -O /usr/local/bin/bbl && \
    chmod +x /usr/local/bin/bbl && \
    wget -q "https://github.com/cloudfoundry/cli/releases/download/v${CF_VERSION}/cf8-cli_${CF_VERSION}_linux_i686.tgz" -O cf.tgz && \
    tar xzf cf.tgz && \
    mv cf8 /usr/local/bin/cf && \
    chmod +x /usr/local/bin/cf

FROM alpine:3.20.3

LABEL maintainer="CloudFoundry Tools" \
      description="Base image with CloudFoundry CLI and related tools (CF CLI, BOSH, CredHub, BBL, Shepherd)" \
      version="1.0"

RUN addgroup -S cloudfoundry && \
    adduser -S -G cloudfoundry cloudfoundry

RUN apk add --no-cache \
    python3 \
    py3-pip \
    curl \
    jq \
    wget \
    tar \
    bash \
    ca-certificates \
    git \
    gcc \
    musl-dev \
    make \
    go

COPY --from=builder /usr/local/bin/cf /usr/local/bin/credhub /usr/local/bin/bosh /usr/local/bin/bbl /usr/local/bin/
COPY --from=shepherd /usr/local/bin/shepherd /usr/local/bin/

ENV GOPATH=/go \
    PATH=/go/bin:$PATH \
    CGO_ENABLED=0 \
    GOPROXY=direct

RUN mkdir -p "$GOPATH/src" "$GOPATH/bin" && chmod -R 777 "$GOPATH"

RUN GOPROXY=direct go install github.com/onsi/ginkgo/v2/ginkgo@latest

RUN chmod +x /usr/local/bin/shepherd && \
    chown -R cloudfoundry:cloudfoundry \
        /usr/local/bin/credhub \
        /usr/local/bin/bosh \
        /usr/local/bin/bbl \
        /usr/local/bin/shepherd \
        /usr/local/bin/cf \
        "$GOPATH"

RUN mkdir -p /workspace && \
    chown -R cloudfoundry:cloudfoundry /workspace

USER cloudfoundry

WORKDIR /workspace

RUN echo "CF Version: $(cf version)" && \
    echo "CredHub Version: $(credhub --version)" && \
    echo "BOSH Version: $(bosh --version)" && \
    echo "BBL Version: $(bbl --version)" && \
    echo "Shepherd Version: $(shepherd version)" && \
    echo "Go Version: $(go version)" && \
    echo "Ginkgo Version: $(ginkgo version)"
