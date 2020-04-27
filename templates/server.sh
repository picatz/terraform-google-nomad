
#!/bin/bash

# Add the Nomad CA PEM
cat > /tmp/nomad-ca.pem << EOF
${ca_cert}
EOF
sudo mv /tmp/nomad-ca.pem /nomad/config/nomad-ca.pem

# Add the Nomad Server PEM
cat > /tmp/server.pem << EOF
${server_cert}
EOF
sudo mv /tmp/server.pem /nomad/config/server.pem

# Add the Nomad Server Private Key PEM
cat > /tmp/server-key.pem << EOF
${server_private_key}
EOF
sudo mv /tmp/server-key.pem /nomad/config/server-key.pem

# Update the {NUMBER-OF-SERVERS} ad-hoc template var
sed -i -e "s/{NUMBER-OF-SERVERS}/${number_of_servers}/g" /nomad/config/agent.hcl

# Update the {GOSSIP-SECRET-KEY} ad-hoc template var
sed -i -e "s/{GOSSIP-KEY}/${gossip_secret_key}/g" /nomad/config/agent.hcl

# Update the {PROJECT-NAME} ad-hoc template var
sed -i -e "s/{PROJECT-NAME}/${project}/g" /nomad/config/agent.hcl

# Update the {ACLs-ENABLED} ad-hoc template var
sed -i -e "s/{ACLs-ENABLED}/${acls_enabled}/g" /nomad/config/agent.hcl

# Update the {PRIVATE-IPV4} ad-hoc template var
IP=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/network-interfaces/0/ip)
sed -i -e "s/{PRIVATE-IPV4}/$${IP}/g" /nomad/config/agent.hcl

# Enable and start Nomad
systemctl enable nomad
systemctl start nomad