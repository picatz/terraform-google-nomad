provider "nomad" {
  address = "http://localhost:4646"
}

resource "nomad_job" "count_dashboard" {
  jobspec = file("../count-dashboard.hcl")
}
