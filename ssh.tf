resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}

resource "local_file" "ssh_public_key" {
  count = var.save_ssh_keypair_locally ? 1 : 0

  content         = tls_private_key.ssh_key.public_key_openssh
  filename        = "bastion.pub"
  file_permission = "0600"
}

resource "local_file" "ssh_private_key" {
  count = var.save_ssh_keypair_locally ? 1 : 0

  content         = tls_private_key.ssh_key.private_key_pem
  filename        = "bastion"
  file_permission = "0600"
}
