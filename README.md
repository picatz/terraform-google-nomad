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

## See the UI

```console
$ gcloud compute ssh nomad-bastion -- -N -L 4646:$(gcloud compute instances list | grep "nomad-server" | head -n 1 | awk '{print $4}'):4646
...
Then go to http://localhost:4646/ui
...
```
