# Prometheus and Grafana Metrics on Nomad using Consul

```console
$ cd ../../                                                                              # in root repository directory with Makefile
$ make terraform/apply                                                                   # build infrastructure
$ export CONSUL_HTTP_TOKEN=$(terraform output -json | jq -r .consul_master_token.value)  # get consul token
$ export LB_IP=$(terraform output -json | jq -r .load_balancer_ip.value)                 # get load balancer ip
$ make ssh/proxy/mtls &                                                                  # start local proxy to connect to nomad and consul servers
$ cd -                                                                                   # come back to the this metrics job directory
```

```console
$ nomad acl bootstrap
Accessor ID  = 7aca82a8-5691-55e0-aa7f-b3fee6d9d29e
Secret ID    = 30f17d6c-d4ff-1b9c-b3b2-fac3a3560979
Name         = Bootstrap Token
Type         = management
Global       = true
Policies     = n/a
Create Time  = 2020-12-13 20:28:52.858532795 +0000 UTC
Create Index = 26
Modify Index = 26
$ export NOMAD_TOKEN="30f17d6c-d4ff-1b9c-b3b2-fac3a3560979"
```

```console
$ consul catalog services
consul
nomad
nomad-client
```

```console
$ cat metrics-consul-policy.hcl
service_prefix "" {
  policy = "read"
}

node_prefix "" {
  policy = "read"
}
$ consul acl policy create -name "metrics" -description "Prometheus metrics" -datacenter "dc1" -rules @metrics-consul-policy.hcl
ID:           d30b02b3-b92d-196c-4d91-51b4cfdafec4
Name:         metrics
Description:  Prometheus metrics
Datacenters:
Rules:
service_prefix "" {
        policy = "read"
}

node_prefix "" {
        policy = "read"
}
$ consul acl role create -name "metrics" -description "Prometheus metrics" -policy-id d30b02b3
ID:           c61a8fe5-a222-a004-5566-d8196f636993
Name:         metrics
Description:  Prometheus metrics
Policies:
   d30b02b3-b92d-196c-4d91-51b4cfdafec4 - metrics

$ consul acl token create -description "Prometheus metrics" -role-id c61a8fe5
AccessorID:       e593b02d-a84b-36ae-b343-9b847fb00b14
SecretID:         b71d99e9-53a5-fbe4-79f7-299f4ee4dd7e
Description:      Prometheus metrics
Local:            false
Create Time:      2020-12-13 22:36:50.26319864 +0000 UTC
Roles:
   c61a8fe5-a222-a004-5566-d8196f636993 - metrics

$ nomad job run -var="consul_metrics_token=b71d99e9-53a5-fbe4-79f7-299f4ee4dd7e" -var="load_balancer_ip=${LB_IP}" metrics.hcl
==> Monitoring evaluation "6981e9cf"
    Evaluation triggered by job "metrics"
    Evaluation within deployment: "136ae5a3"
    Allocation "b3154462" created: node "cbc0f642", group "grafana"
    Allocation "d46442e4" created: node "cbc0f642", group "prometheus"
    Evaluation status changed: "pending" -> "complete"
==> Evaluation "6981e9cf" finished with status "complete"
```
