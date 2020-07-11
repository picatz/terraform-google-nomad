# Nomad Cluster

[![Nomad Version](https://img.shields.io/badge/Nomad%20Version-0.12.0-brightgreen.svg)](https://www.nomadproject.io/downloads)

[Terraform](https://www.terraform.io/) Module for [Nomad](https://nomadproject.io/) clusters on [GCP](https://cloud.google.com/).

## Cloud Shell Interactive Tutorial

[![Open in Cloud Shell](https://gstatic.com/cloudssh/images/open-btn.svg)](https://ssh.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https%3A%2F%2Fgithub.com%2Fpicatz%2Fterraform-google-nomad&cloudshell_print=cloud-shell%2Fprint.txt&cloudshell_tutorial=cloud-shell%2Fsteps.md&shellonly=true)

<details><summary>Manual Steps for Development</summary>
<p>

## Bootstrap a brand new GCP project using [`gcloud`](https://cloud.google.com/sdk/gcloud)

Bootstrap a new GCP using the `setup_gcp.sh` shell script:

```console
$ bash setup_gcp.sh $YOUR_PROJECT_NAME
...
```

It will automatically create, link the billing account, and enable the compute API in GCP.

### Set Environment Variables

Using your GCP project name and new created `account.json` Terraform service account file from the previous step:

```console
$ export GOOGLE_APPLICATION_CREDENTIALS=$(realpath account.json)
$ export GOOGLE_PROJECT="$YOUR_PROJECT_NAME"
```

## Build the Bastion/Server/Client Images with Packer

```console
$ cd packer
$ packer build template.json
...
```

## Build Infrastructure

```console
$ terraform plan -var="project=$GOOGLE_PROJECT" -var="credentials=$GOOGLE_APPLICATION_CREDENTIALS"
...
$ terraform apply -var="project=$GOOGLE_PROJECT" -var="credentials=$GOOGLE_APPLICATION_CREDENTIALS"
...
```

</p>
</details>


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

When using the SSH bastion, you can use the `ssh-mtls-terminating-proxy.go` helper script to tunnel a connection from localhost the Nomad server API:

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

Then open your browser at `http://localhost:4646/ui/` to securely access the Nomad UI.
