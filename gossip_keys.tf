resource "random_password" "nomad-gossip-key" {
  length  = 16
  special = true
}

resource "random_password" "consul-gossip-key" {
  length  = 16
  special = true
}
