FROM ubuntu:22.04

# Install required packages
RUN apt-get update && apt-get install -y \
    curl \
    jq \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install shepherd CLI
RUN curl -sSL https://storage.googleapis.com/shepherd-cli/latest/shepherd-linux-amd64 -o /usr/local/bin/shepherd \
    && chmod +x /usr/local/bin/shepherd

WORKDIR /workspace
