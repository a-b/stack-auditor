FROM alpine:3.19

RUN apk add --no-cache \
    curl \
    jq \
    ca-certificates \
    bash

RUN curl -sSL https://storage.googleapis.com/shepherd-cli/latest/shepherd-linux-amd64 -o /usr/local/bin/shepherd \
    && chmod +x /usr/local/bin/shepherd

WORKDIR /workspace
