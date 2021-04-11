# Deploy Prometheus and Grafana on Nomad using Consul

```console
$ nomad run -var="consul_acl_token=$CONSUL_METRICS_TOKEN" -var="consul_lb_ip=$CONSUL_LB_IP" metrics.hcl
...
```
