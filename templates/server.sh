
#!/bin/bash

# CONSUL CONFIGURATION

# Add the Consul CA PEM
cat > /tmp/consul-ca.pem << EOF
${consul_ca_cert}
EOF
sudo mv /tmp/consul-ca.pem /etc/consul.d/consul-ca.pem

# Add the Consul Server PEM
cat > /tmp/server.pem << EOF
${consul_server_cert}
EOF
sudo mv /tmp/server.pem /etc/consul.d/server.pem

# Add the Consul Server Private Key PEM
cat > /tmp/server-key.pem << EOF
${consul_server_private_key}
EOF
sudo mv /tmp/server-key.pem /etc/consul.d/server-key.pem

# Update the {NUMBER-OF-SERVERS} ad-hoc template var
sed -i -e "s/{NUMBER-OF-SERVERS}/${number_of_servers}/g" /etc/consul.d/consul.hcl

# Update the {GOSSIP-SECRET-KEY} ad-hoc template var
sed -i -e "s/{GOSSIP-KEY}/${consul_gossip_secret_key}/g" /etc/consul.d/consul.hcl

# Update the {PROJECT-NAME} ad-hoc template var
sed -i -e "s/{PROJECT-NAME}/${project}/g" /etc/consul.d/consul.hcl

# Update the {ACLs-ENABLED} ad-hoc template var
sed -i -e "s/{ACLs-ENABLED}/${consul_acls_enabled}/g" /etc/consul.d/consul.hcl

# Update the {ACLs-DEFAULT-POLICY} ad-hoc template var
sed -i -e "s/{ACLs-DEFAULT-POLICY}/${consul_acls_default_policy}/g" /etc/consul.d/consul.hcl

# Set ACL master token if ACLs are enabled
if [ "${consul_acls_enabled}" = "true" ]; then
    sed -i -e "s/{CONSUL-TOKEN}/${consul_master_token}/g" /etc/nomad.d/nomad.hcl
    sed -i -e "s/{CONSUL-TOKEN}/${consul_master_token}/g" /etc/consul.d/consul.hcl
else
    sed -i -e "s/{CONSUL-TOKEN}//g" /etc/nomad.d/nomad.hcl
    sed -i -e "s/{CONSUL-TOKEN}//g" /etc/consul.d/consul.hcl
fi

# Update the {PRIVATE-IPV4} ad-hoc template var
IP=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/network-interfaces/0/ip)
sed -i -e "s/{PRIVATE-IPV4}/$${IP}/g" /etc/consul.d/consul.hcl

# Enable and start Consul
systemctl enable consul
systemctl start consul

# NOMAD CONFIGURATION

# Add the Nomad CA PEM
cat > /tmp/nomad-ca.pem << EOF
${nomad_ca_cert}
EOF
sudo mv /tmp/nomad-ca.pem /etc/nomad.d/nomad-ca.pem

# Add the Nomad Server PEM
cat > /tmp/server.pem << EOF
${nomad_server_cert}
EOF
sudo mv /tmp/server.pem /etc/nomad.d/server.pem

# Add the Nomad Server Private Key PEM
cat > /tmp/server-key.pem << EOF
${nomad_server_private_key}
EOF
sudo mv /tmp/server-key.pem /etc/nomad.d/server-key.pem

# Update the {NUMBER-OF-SERVERS} ad-hoc template var
sed -i -e "s/{NUMBER-OF-SERVERS}/${number_of_servers}/g" /etc/nomad.d/nomad.hcl

# Update the {GOSSIP-SECRET-KEY} ad-hoc template var
sed -i -e "s/{GOSSIP-KEY}/${nomad_gossip_secret_key}/g" /etc/nomad.d/nomad.hcl

# Update the {PROJECT-NAME} ad-hoc template var
sed -i -e "s/{PROJECT-NAME}/${project}/g" /etc/nomad.d/nomad.hcl

# Update the {ACLs-ENABLED} ad-hoc template var
sed -i -e "s/{ACLs-ENABLED}/${nomad_acls_enabled}/g" /etc/nomad.d/nomad.hcl

# Update the {PRIVATE-IPV4} ad-hoc template var
IP=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/network-interfaces/0/ip)
sed -i -e "s/{PRIVATE-IPV4}/$${IP}/g" /etc/nomad.d/nomad.hcl

# Enable and start Nomad
systemctl enable nomad
systemctl start nomad