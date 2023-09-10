#!/bin/bash

set -ex

# https://github.com/hashicorp/packer/issues/2639
timeout 180 /usr/bin/cloud-init status --wait

sudo apt-get update -y
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    unzip \
    curl \
    wget \
    gpg \
    coreutils \
    gnupg-agent \
    software-properties-common \
    jq