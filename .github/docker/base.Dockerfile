FROM us-west2-docker.pkg.dev/shepherd-268822/shepherd2/concourse-resource:latest

# Version variables that can be overridden to lock specific versions
ENV CREDHUB_VERSION="" \
    BOSH_VERSION="" \
    BBL_VERSION=""

# Install all prerequisites in a single layer to reduce image size
RUN set -eux; \
    apt-get update -qq && \
    # Install CF CLI
    curl -fsSL https://packages.cloudfoundry.org/debian/cli.cloudfoundry.org.key | \
    gpg --dearmor -o /usr/share/keyrings/cloudfoundry-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/cloudfoundry-keyring.gpg] https://packages.cloudfoundry.org/debian stable main" | \
    tee /etc/apt/sources.list.d/cloudfoundry.list > /dev/null && \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        cf8-cli \
        jq \
        wget \
        ca-certificates \
        && \
    # Set versions to latest if not provided
    [ -n "$CREDHUB_VERSION" ] || CREDHUB_VERSION=$(curl -s https://api.github.com/repos/cloudfoundry/credhub-cli/releases/latest | jq -r .tag_name) && \
    [ -n "$BOSH_VERSION" ] || BOSH_VERSION=$(curl -s https://api.github.com/repos/cloudfoundry/bosh-cli/releases/latest | jq -r .tag_name[1:]) && \
    [ -n "$BBL_VERSION" ] || BBL_VERSION=$(curl -s https://api.github.com/repos/cloudfoundry/bosh-bootloader/releases/latest | jq -r '.tag_name[1:]') && \
    # Install Credhub CLI
    wget -q "https://github.com/cloudfoundry/credhub-cli/releases/download/${CREDHUB_VERSION}/credhub-linux-amd64-${CREDHUB_VERSION}.tgz" && \
    tar xzf "credhub-linux-amd64-${CREDHUB_VERSION}.tgz" && \
    mv credhub /usr/local/bin/ && \
    rm "credhub-linux-amd64-${CREDHUB_VERSION}.tgz" && \
    # Install BOSH CLI
    wget -q "https://github.com/cloudfoundry/bosh-cli/releases/download/v${BOSH_VERSION}/bosh-cli-${BOSH_VERSION}-linux-amd64" -O bosh && \
    chmod +x bosh && \
    mv bosh /usr/local/bin/ && \
    # Install BBL CLI
    wget -q "https://github.com/cloudfoundry/bosh-bootloader/releases/download/v${BBL_VERSION}/bbl-v${BBL_VERSION}_linux_amd64" -O bbl && \
    chmod +x bbl && \
    mv bbl /usr/local/bin/ && \
    # Clean up
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    # Verify installations
    cf version && \
    credhub --version && \
    bosh --version && \
    bbl --version
