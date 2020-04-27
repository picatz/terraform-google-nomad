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
sed -i -e "s/{ACLs-ENABLED}/${acls_enabled}/g" /nomad/config/agent.hc

# Update the {PROJECT-NAME} ad-hoc template var
sed -i -e "s/{PROJECT-NAME}/${project}/g" /nomad/config/agent.hcl

# Enable and start Nomad
systemctl enable nomad
systemctl start nomad