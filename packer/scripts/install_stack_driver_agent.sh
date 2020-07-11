#!/bin/bash

set -ex

# OLD WAY:
# curl -s https://dl.google.com/cloudagents/install-logging-agent.sh | sudo bash

# NEW WAY:
# https://cloud.google.com/logging/docs/agent/installation#agent-install-debian-ubuntu
curl -sSO https://dl.google.com/cloudagents/add-logging-agent-repo.sh
sudo bash add-logging-agent-repo.sh
sudo apt-get update
sudo apt-get install -y google-fluentd
sudo apt-get install -y google-fluentd-catch-all-config-structured
sudo systemctl enable google-fluentd