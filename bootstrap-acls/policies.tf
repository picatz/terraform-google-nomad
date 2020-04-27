resource "nomad_acl_policy" "admin" {
  name        = "admin"
  description = "Policy for Nomad admins."
  rules_hcl   = file("${path.module}/acl-policies/admin.hcl")
}
