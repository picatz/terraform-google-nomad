#!/bin/bash

set -ex

# install gcfuse
export GCSFUSE_REPO=gcsfuse-`lsb_release -c -s`
echo "deb http://packages.cloud.google.com/apt $GCSFUSE_REPO main" | sudo tee /etc/apt/sources.list.d/gcsfuse.list
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
sudo apt-get update -y
sudo apt-get install gcsfuse -y

# setup systemd service
sudo touch /etc/systemd/system/gcsfuse.service
sudo mv /tmp/gcsfuse.service /etc/systemd/system/gcsfuse.service
sudo systemctl daemon-reload

# and create the eventual mount path
sudo mkdir /gcs

# and create systemd environment file
# which will be populate by terraform dynamically with the bucket name
# environment variable used by gcsfuse
sudo touch /etc/gcsfuse.env