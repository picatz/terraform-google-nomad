#!/bin/bash

# Add the Nomad CA PEM
cat > /tmp/nomad-ca.pem << EOF
${ca_cert}
EOF
sudo mv /tmp/nomad-ca.pem /nomad/config/nomad-ca.pem

# Add the Nomad Client PEM
cat > /tmp/client.pem << EOF
${client_cert}
EOF
sudo mv /tmp/client.pem /nomad/config/client.pem

# Add the Nomad Server Private Key PEM
cat > /tmp/client-key.pem << EOF
${client_private_key}
EOF
sudo mv /tmp/client-key.pem /nomad/config/client-key.pem

# Update the {ACLs-ENABLED} ad-hoc template var
sed -i -e "s/{ACLs-ENABLED}/${acls_enabled}/g" /nomad/config/agent.hcl

# Update the {PROJECT-NAME} ad-hoc template var
sed -i -e "s/{PROJECT-NAME}/${project}/g" /nomad/config/agent.hcl

# If gVsior is enabled, then install it
if [ "${gvisor_enabled}" = "true" ]; then
    curl -fsSL https://gvisor.dev/archive.key | sudo apt-key add -
    add-apt-repository "deb https://storage.googleapis.com/gvisor/releases ${gvisor_release} main"
    apt-get update && sudo apt-get install -y runsc
    runsc install
fi

# Configure default docker runtime
cat /etc/docker/daemon.json  | jq '{"default-runtime": "${docker_default_runtime}"} + .' > /tmp/daemon.json
cat /tmp/daemon.json > /etc/docker/daemon.json
rm /tmp/daemon.json

# Optionally enable no-new-privileges
if [ "${docker_no_new_privileges}" = "true" ]; then
    cat /etc/docker/daemon.json  | jq '. + {"no-new-privileges": true}' > /tmp/daemon.json
    cat /tmp/daemon.json > /etc/docker/daemon.json
    rm /tmp/daemon.json
fi

# Optionally disable icc
if [ "${docker_icc_enabled}" = "false" ]; then
    cat /etc/docker/daemon.json  | jq '. + {"icc": false}' > /tmp/daemon.json
    cat /tmp/daemon.json > /etc/docker/daemon.json
    rm /tmp/daemon.json
fi

# Restart docker to apply changes
systemctl restart docker

# Start and enable Nomad
systemctl start nomad
systemctl enable nomad
