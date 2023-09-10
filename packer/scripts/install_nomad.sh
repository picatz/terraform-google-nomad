#!/bin/bash

set -ex

# Download Latest Version of Nomad
# https://developer.hashicorp.com/nomad/docs/install
sudo apt-get install -y nomad

# Move /tmp/nomad.hcl to /etc/nomad.d/nomad.hcl
sudo mv /tmp/nomad-agent.hcl /etc/nomad.d/nomad.hcl