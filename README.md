# nomad-cluster

[Terraform](https://www.terraform.io/) Module for [Nomad](https://nomadproject.io/) clusters on [GCP](https://cloud.google.com/).

## Bootstrap a brand new GCP project using `gcloud`

I created a project named `my-nomad-cluster` using the following command (you will need to use a different project name):

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

```console
$ terraform plan -var="project=my-nomad-cluster"
...
$ terraform apply -var="project=my-nomad-cluster"
...
```

## Bootstrap ACL Token

If the cluster is started with ACLs enabled, which is the default behavior of this module, you may see this:

```console
$ export NOMAD_ADDR="https://$(terraform output -json | jq -r .load_balancer_ip.value):4646"
$ nomad status
Error querying jobs: Unexpected response code: 403 (Permission denied)
```

We can bootstrap ACLs to get the bootstrap management token like so:

```console
$ nomad acl bootstrap
Accessor ID  = a1495889-37ce-6784-78f3-3190a1984bca
Secret ID    = dc8c0349-c1fd-dc2c-299c-d513e5dd6df2
Name         = Bootstrap Token
Type         = management
Global       = true
Policies     = n/a
Create Time  = 2020-04-27 05:24:43.734587566 +0000 UTC
Create Index = 7
Modify Index = 7
```

Then we can use that token (Secret ID) to perform the rest of the ACL bootstrapping process:

```console
$ export NOMAD_TOKEN="dc8c0349-c1fd-dc2c-299c-d513e5dd6df2"
$ nomad status
No running jobs
$ ...
```

## Use `ssh-mtls-terminating-proxy` to access the Nomad UI

```console
$ go run ssh-mtls-terminating-proxy.go
2020/04/27 01:27:38 Getting Terraform Output
2020/04/27 01:27:38 Bastion IP: "104.196.121.185"
2020/04/27 01:27:38 Server IP: "192.168.2.3"
2020/04/27 01:27:38 Setting up SSH agent
2020/04/27 01:27:38 Connecting to the bastion
2020/04/27 01:27:41 Connecting to the server through the bastion
2020/04/27 01:27:44 Wrapping the server connection with SSH through the bastion
2020/04/27 01:27:45 Tunneling a connection to the server with SSH through the bastion
2020/04/27 01:27:45 Loading the TLS data
2020/04/27 01:27:45 Starting local listener on localhost:4646
...
```

Then open your browser at `http://localhost:4646/ui/` to see the Nomad UI exposed securley on your localhost.
