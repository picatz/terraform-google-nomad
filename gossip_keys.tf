resource "random_id" "nomad-gossip-key" {
  byte_length = 32
}

resource "random_id" "consul-gossip-key" {
  byte_length = 32
}
