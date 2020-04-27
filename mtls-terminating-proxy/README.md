# `mtls-terminating-proxy`

```console
$ go run main.go --lb-ip="$PUBLIC_IP" --ca-file="../nomad-ca.pem" --cert-file="../nomad-cli-cert.pem" --key-file="../nomad-cli-key.pem"
2020/04/26 23:10:07 Load Balancer IP: "$PUBLIC_IP"
2020/04/26 23:10:07 Loading the TLS data
2020/04/26 23:10:07 Starting local listener on localhost:4646
```
