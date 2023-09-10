#!/bin/bash

set -ex

# sudo mv /tmp/docker_auth_config.json /nomad/config
# sudo chown root:root /nomad/config/docker_auth_config.json
# 
# VERSION=2.0.0
# OS=linux  # or "darwin" for OSX, "windows" for Windows.
# ARCH=amd64  # or "386" for 32-bit OSs, "arm64" for ARM 64.
# 
# curl -fsSL "https://github.com/GoogleCloudPlatform/docker-credential-gcr/releases/download/v${VERSION}/docker-credential-gcr_${OS}_${ARCH}-${VERSION}.tar.gz" \
# | tar xz --to-stdout ./docker-credential-gcr \
# > /tmp/docker-credential-gcr
# 
# sudo mv /tmp/docker-credential-gcr /usr/local/bin/ 
# sudo chmod +x /usr/local/bin/docker-credential-gcr