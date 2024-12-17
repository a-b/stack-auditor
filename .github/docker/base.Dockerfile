# syntax=docker/dockerfile:1.4
FROM us-west2-docker.pkg.dev/shepherd-268822/shepherd2/concourse-resource:latest as shepherd

FROM golang:alpine3.20 as go-builder
RUN go install github.com/onsi/ginkgo/v2/ginkgo@latest

FROM alpine:3.20.3

LABEL maintainer="CloudFoundry Tools" \
      description="Base image with CloudFoundry CLI and related tools (CF CLI, BOSH, CredHub, BBL, Shepherd)" \
      version="1.0"

ARG GITHUB_TOKEN

RUN apk add --no-cache \
    bash \
    ca-certificates \
    curl \
    git \
    jq \
    python3 \
    py3-pip \
    wget \
    go && \
    addgroup -S cloudfoundry && \
    adduser -S -G cloudfoundry cloudfoundry

RUN set -eux; \
    CREDHUB_VERSION=$(curl -sH "Authorization: token ${GITHUB_TOKEN}" https://api.github.com/repos/cloudfoundry/credhub-cli/releases/latest | jq -r .tag_name) && \
    BOSH_VERSION=$(curl -sH "Authorization: token ${GITHUB_TOKEN}" https://api.github.com/repos/cloudfoundry/bosh-cli/releases/latest | jq -r '.tag_name[1:]') && \
    BBL_VERSION=$(curl -sH "Authorization: token ${GITHUB_TOKEN}" https://api.github.com/repos/cloudfoundry/bosh-bootloader/releases/latest | jq -r '.tag_name[1:]') && \
    CF_VERSION=$(curl -sH "Authorization: token ${GITHUB_TOKEN}" https://api.github.com/repos/cloudfoundry/cli/releases/latest | jq -r '.tag_name[1:]') && \
    echo "Installing CredHub CLI version: $CREDHUB_VERSION" && \
    echo "Installing BOSH CLI version: $BOSH_VERSION" && \
    echo "Installing BBL version: $BBL_VERSION" && \
    echo "Installing CF CLI version: $CF_VERSION" && \
    wget -q "https://github.com/cloudfoundry/credhub-cli/releases/download/${CREDHUB_VERSION}/credhub-linux-amd64-${CREDHUB_VERSION}.tgz" && \
    tar xzf "credhub-linux-amd64-${CREDHUB_VERSION}.tgz" && \
    mv credhub /usr/local/bin/ && \
    wget -q "https://github.com/cloudfoundry/bosh-cli/releases/download/v${BOSH_VERSION}/bosh-cli-${BOSH_VERSION}-linux-amd64" -O /usr/local/bin/bosh && \
    chmod +x /usr/local/bin/bosh && \
    wget -q "https://github.com/cloudfoundry/bosh-bootloader/releases/download/v${BBL_VERSION}/bbl-v${BBL_VERSION}_linux_amd64" -O /usr/local/bin/bbl && \
    chmod +x /usr/local/bin/bbl && \
    wget -q "https://packages.cloudfoundry.org/stable?release=linux64-binary&version=${CF_VERSION}" -O cf.tgz && \
    tar xzf cf.tgz && \
    mv cf8 /usr/local/bin/cf && \
    chmod +x /usr/local/bin/cf && \
    rm -rf *.tgz && \
    mkdir -p /workspace && \
    chown -R cloudfoundry:cloudfoundry /workspace

COPY --from=shepherd /usr/local/bin/shepherd /usr/local/bin/
COPY --from=go-builder /go/bin/ginkgo /usr/local/bin/

RUN chmod +x /usr/local/bin/shepherd && \
    chown -R cloudfoundry:cloudfoundry \
        /usr/local/bin/credhub \
        /usr/local/bin/bosh \
        /usr/local/bin/bbl \
        /usr/local/bin/shepherd \
        /usr/local/bin/cf \
        /usr/local/bin/ginkgo

USER cloudfoundry
WORKDIR /workspace

RUN echo "CF Version: $(cf version)" && \
    echo "CredHub Version: $(credhub --version)" && \
    echo "BOSH Version: $(bosh --version)" && \
    echo "BBL Version: $(bbl --version)" && \
    echo "Shepherd Version: $(shepherd version)" && \
    echo "Go Version: $(go version)" && \
    echo "Ginkgo Version: $(ginkgo version)"
