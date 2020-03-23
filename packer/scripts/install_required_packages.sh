#!/bin/bash

set -ex

# https://github.com/hashicorp/packer/issues/2639
timeout 180 /usr/bin/cloud-init status --wait

sudo apt-get update
sudo apt-get install -y unzip