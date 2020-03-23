locals {
    gossip_key = base64encode(random_password.gossip.result)
}

locals {
  nomad_bootstrap_script = <<EOF
#!/bin/bash
IP=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/network-interfaces/0/ip)
sed -i -e "s/{PRIVATE-IPV4}/$${IP}/g" /nomad/config/agent.hcl
sed -i -e "s/{NUMBER-OF-SERVERS}/${var.server_instances}/g" /nomad/config/agent.hcl
sed -i -e "s/{GOSSIP-KEY}/${local.gossip_key}/g" /nomad/config/agent.hcl
sed -i -e "s/{PROJECT-NAME}/${var.project}/g" /nomad/config/agent.hcl
systemctl enable nomad
systemctl start nomad
EOF
}