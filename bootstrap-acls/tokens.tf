resource "nomad_acl_token" "admin" {
  type     = "client"
  name     = "admin"
  policies = [nomad_acl_policy.admin.name]
}