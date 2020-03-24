resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
}

resource "local_file" "ssh_public_key" {
  content    = tls_private_key.ssh_key.public_key_openssh
  filename   = "bastion.pub"
}

resource "local_file" "ssh_private_key" {
  content    = tls_private_key.ssh_key.private_key_pem
  filename   = "bastion"
}