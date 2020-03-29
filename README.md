# nomad-cluster

Terraform Module for Nomad clusters on GCP

## Bootstrap a brand new GCP project using `gcloud`

I created a project named `my-nomad-cluster` using the following command:

```console
$ bash setup_gcp.sh my-nomad-cluster
...
```

It will automatically create, link the billing account, and enable the compute API in GCP.

## Use Generated `account.json`

```console
$ export GOOGLE_APPLICATION_CREDENTIALS=$(realpath account.json)
$ export GOOGLE_PROJECT="my-nomad-cluster"
```

## Build the Bastion/Server/Client Images with Packer

```console
$ cd packer
$ packer build template.json
...
```

## Build Infrastructure

```consoel
$ terraform apply
...
```

## SSH Through Bastion to expose mTLS Nomad endpoint on `localhost`

```console
$ ssh-add -k bastion
$ export NOMAD_BASTION_IP=$(gcloud compute instances list | grep "nomad-bastion" | head -n 1 | awk '{print $5}')
$ export NOMAD_SERVER_IP=$(gcloud compute instances list | grep "nomad-server" | head -n 1 | awk '{print $4}')
$ ssh -N -L 4646:127.0.0.1:4646 -A "ubuntu@${NOMAD_SERVER_IP}" -o "proxycommand ssh -W %h:%p -A ubuntu@${NOMAD_BASTION_IP}"
...
```

In another terminal ( that isn't running the SSH tunnel ):

```console
$ export NOMAD_ADDR=https://localhost:4646
$ export NOMAD_CACERT=$(realpath ./packer/certs/nomad-ca.pem)
$ export NOMAD_CLIENT_CERT=$(realpath ./packer/certs/cli.pem)
$ export NOMAD_CLIENT_KEY=$(realpath ./packer/certs/cli-key.pem)
$ nomad node status -verbose
ID                                    DC   Name            Class   Address      Version  Drain  Eligibility  Status
efdec0c9-adc1-ca7b-71aa-ec593075a410  dc1  nomad-client-0  <none>  192.168.2.2  0.10.5   false  eligible     ready
```

## Use `ssh-mtls-terminating-proxy` to access the Nomad UI

```console
$ ssh-add -k bastion
$ export NOMAD_BASTION_IP=$(gcloud compute instances list | grep "nomad-bastion" | head -n 1 | awk '{print $5}')
$ export NOMAD_SERVER_IP=$(gcloud compute instances list | grep "nomad-server" | head -n 1 | awk '{print $4}')
$ cd ssh-mtls-terminating-proxy
$ go run main.go --bastion-ip=$NOMAD_BASTION_IP --server-ip=$NOMAD_SERVER_IP --ca-file=../packer/certs/nomad-ca.pem --cert-file=../packer/certs/cli.pem --key-file=../packer/certs/cli-key.pem
2020/03/23 23:03:02 Starting local listener on localhost:4646
...
```

Then open your browser at `http://localhost:4646/ui/` to see the Nomad UI exposed securley on your localhost.
