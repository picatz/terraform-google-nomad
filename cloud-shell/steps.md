# Deploy a Nomad Cluster to GCP

## Welcome!

👩🏽‍💻This tutorial will teach you how to deploy [Nomad](https://www.nomadproject.io/) clusters to the Google Cloud Platform using [Packer](https://www.packer.io/) and [Terraform](https://www.terraform.io/)!

**Includes**:

1. 🛠 Setting up your cloud shell environment with `nomad`, `packer`, and `terraform` binaries.
2. ⚙️  Configuring a new GCP project, linking the billing account, and enabling the compute engine API using `gcloud`.
3. 📦 Packaging cluster golden images (bastion, server, and client) with `packer`.
4. ☁️  Deploying a Nomad cluster using `terraform`.
5. 🔐 Bootstrapping the [ACL system](https://learn.hashicorp.com/nomad/acls/fundamentals), obtaining a administrative management token.
6. 🐳 Submitting an example job as a Docker container running [Folding at Home](https://foldingathome.org/) to the cluster, tailing the logs, and then stopping the container.

## Setup Environment

Before we can deploy our cluster, we need to setup our environment with the required HashiCorp tools.

### Download Nomad

Download the latest version of [Nomad](https://www.nomadproject.io/) from HashiCorp's website by copying and pasting this snippet in the terminal:

```console
curl "https://releases.hashicorp.com/nomad/0.12.0/nomad_0.12.0_linux_amd64.zip" -o nomad.zip
unzip nomad.zip
sudo mv nomad /usr/local/bin
nomad --version
```

### Download Packer

Download the latest version of [Packer](https://www.packer.io/) from HashiCorp's website by copying and pasting this snippet in the terminal:

```console
curl "https://releases.hashicorp.com/packer/1.6.0/packer_1.6.0_linux_amd64.zip" -o packer.zip
unzip packer.zip
sudo mv packer /usr/local/bin
packer --version
```

### Download Terraform

Download the latest version of [Terraform](https://www.terraform.io/) from HashiCorp's website by copying and pasting this snippet in the terminal:

```console
curl "https://releases.hashicorp.com/terraform/0.12.28/terraform_0.12.28_linux_amd64.zip" -o terraform.zip
unzip terraform.zip
sudo mv terraform /usr/local/bin
terraform --version
```

🎉 You have now installed `nomad`, `packer`, and `terraform`!

### Next Step

Now that we have our tools, let's configure our GCP project.

## Configure GCP Project

Before building our infrastructure, we'll need to do a few things:

1. Create a new GCP project.
2. Link a billing account to that project.
3. Enable the [compute engine](https://cloud.google.com/compute).
4. Create a Terraform Service Account, with a credentials file (`account.json`).
5. Set the required environment variables to move onto the next steps.

### Create a New Project

To get started, let's create a new GCP project with the following command:

```console
gcloud projects create your-new-project-name
```

Now export the project name as the `GOOGLE_PROJECT` environment variable:

```console
export GOOGLE_PROJECT="your-new-project-name"
```

And then set your `gcloud` config to use that project:

```console
gcloud config set project $GOOGLE_PROJECT
```

### Link Billing Account to Project

Next, let's link a billing account to that project. To determine what billing accounts are available, run the following command:

```console
gcloud alpha billing accounts list
```

Then set the billing account ID `GOOGLE_BILLING_ACCOUNT` environment variable:

```console
export GOOGLE_BILLING_ACCOUNT="XXXXXXX"
```

So we can link the `GOOGLE_BILLING_ACCOUNT` with the previously created `GOOGLE_PROJECT`:

```console
gcloud alpha billing projects link "$GOOGLE_PROJECT" --billing-account "$GOOGLE_BILLING_ACCOUNT"
```

### Enable Compute API

In order to deploy VMs to the project, we need to enable the compute API:

```console
gcloud services enable compute.googleapis.com
```

> ℹ️  **Note**
>
> The command will take a few minutes to complete.

### Create Terraform Service Account

Finally, let's create a Terraform Service Account user and its `account.json` credentials file:

```console
gcloud iam service-accounts create terraform \
    --display-name "Terraform Service Account" \
    --description "Service account to use with Terraform"
```

```console
gcloud projects add-iam-policy-binding "$GOOGLE_PROJECT" \
  --member serviceAccount:"terraform@$GOOGLE_PROJECT.iam.gserviceaccount.com" \
  --role roles/editor
```

```console
gcloud iam service-accounts keys create account.json \
    --iam-account "terraform@$GOOGLE_PROJECT.iam.gserviceaccount.com"
```

> ⚠️  **Warning**
>
> The `account.json` credentials gives privelleged access to this GCP project. Be sure to prevent from accidently leaking these credentials in version control systems such as `git`. In general, as an operator on your own host machine, or in your own GCP cloud shell is ok. However, using a secrets management system like HashiCorp [Vault](https://www.vaultproject.io/) can often be a better solution for teams. For this tutorial's purposes, we'll be storing the `account.json` credentials on disk in the cloud shell.

Now set the *full path* of the newly created `account.json` file as `GOOGLE_APPLICATION_CREDENTIALS` environment variable.

```console
export GOOGLE_APPLICATION_CREDENTIALS=$(realpath account.json)
```

### Ensure Required Environment Variables Are Set

Before moving onto the next steps, ensure the following environment variables are set:

* `GOOGLE_PROJECT` with your selected GCP project name.
* `GOOGLE_APPLICATION_CREDENTIALS` with the *full path* to the Terraform Service Account `account.json` credentials file created with the last step.

## Build Images with Packer

To build the cluster images, change into the `packer` directory:

```console
cd packer
```

And then run the following command which will use the `template.json` file to build the bastion, server, and client images in parallel.

```console
packer build -force template.json
```

> ℹ️ **Note**
>
> The command will take about 5 minutes to complete.

Once the command completes successfully, change back to previous folder to move onto the next phase:

```console
cd ..
```

## Deploy Infrastructure with Terraform

🙌🏽 Now to finally deploy the Nomad cluster using Terraform!

### Example Configuration

The `example` directory contains an simple Terraform configuration using the [`picatz/google/nomad`](https://registry.terraform.io/modules/picatz/nomad/google) module:

> ℹ️ **Terraform Configuration**
>
> The `example/main.tf` file contains:
>
> ```hcl
> variable "project" {
>     description = "The GCP project name to deploy the cluster to."
> }
>
> variable "credentials" {
>     description = "The GCP credentials file path to use, preferably a Terraform Service Account."
> }
>
> module "nomad" {
>   source           = "picatz/nomad/google"
>   version          = "2.7.8"
>   project          = var.project
>   credentials      = var.credentials
>   bastion_enabled  = false
>   server_instances = 1
>   client_instances = 1
> }
> ```

The configuration disables the default SSH bastion to the cluster, as well as running only one server and client node to save costs.

### Initialize Terraform

Run the following command to change into the `example` directory:

```console
cd example
```

Then initialize Terraform which will download the module from the Terraform Registry:

```console
terraform init
```

### Plan Changes

To plan our infrastructure changes, use `terraform plan`:

```console
terraform plan -var="project=$GOOGLE_PROJECT" -var="credentials=$GOOGLE_APPLICATION_CREDENTIALS"
```

### Apply Changes

To apply the changes, actually creating the cluster:

```console
terraform apply -auto-approve -var="project=$GOOGLE_PROJECT" -var="credentials=$GOOGLE_APPLICATION_CREDENTIALS"
```

> ℹ️ **Note**
>
> The command will take about 5 minutes to complete.

### Set Environment Variables

Using the Terraform outputs, we can set the required Nomad environment variables to securely access to the Nomad cluster API using the TLS information, and load balancer created with the previous step:

```console
export NOMAD_ADDR="https://$(terraform output -json | jq -r .load_balancer_ip.value):4646"
export NOMAD_CACERT="$(realpath nomad-ca.pem)"
export NOMAD_CLIENT_CERT="$(realpath nomad-cli-cert.pem)"
export NOMAD_CLIENT_KEY="$(realpath nomad-cli-key.pem)"
```

## Bootstrap ACL System

To create an administrative management token (only meant to be used by Nomad Administrators), run the following command:

```console
nomad acl bootstrap
```

> ℹ️ **Note**
>
> If the command above errors due to an i/o timeout, try rerunning the command again. This will happen when attempting to `bootstrap` a cluster that hasn't started yet. This should only take a few minutes at the most.

Then we can use the token (Secret ID) in the previous command's output to access the cluster by setting the `NOMAD_TOKEN` environment variable:

```console
export NOMAD_TOKEN="XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
```

To verify access to the Nomad API, run the following command:

```console
nomad status
```

Which should output:

```plaintext
No running jobs
```

> ℹ️ **Learn How To Create Custom ACLs**
>
> Now that you have a management token, you can [learn ACL system fundamentals](https://learn.hashicorp.com/nomad/acls/fundamentals) to tune the ACL system for your cluster's needs.

### Run a Docker Container

Now that we deployed the cluster, let's use it to submit an example job using a Docker container to run [Folding at Home](https://foldingathome.org/):

```hcl
job "folding-at-home" {
  datacenters = ["dc1"]
    group "folding-at-home" {
      task "folding-at-home" {
        driver = "docker"
          config {
            image  = "kentgruber/fah-client:latest"
          }
      }
    }
}
```

> ℹ️ **Note**
>
> There are many other [task drivers](https://www.nomadproject.io/docs/drivers) available for Nomad, but the `picatz/google/nomad` module is setup to support just the [Docker Driver](https://www.nomadproject.io/docs/drivers/docker) by default.
>

To submit the job to the cluster, run the following command using the `jobs/folding-at-home.hcl` job file:

```console
nomad run jobs/folding-at-home.hcl
```

Command output will look *something* like this:

```plaintext
==> Monitoring evaluation "c01bbaa9"
    Evaluation triggered by job "folding-at-home"
    Evaluation within deployment: "811df760"
    Allocation "6311f4ea" created: node "fab91380", group "folding-at-home"
    Evaluation status changed: "pending" -> "complete"
==> Evaluation "c01bbaa9" finished with status "complete"
```

Now check the status of the cluster again:

```console
nomad status
```

Output will look *something* like this:

```plaintext
ID               Type     Priority  Status   Submit Date
folding-at-home  service  50        running  2020-07-11T19:36:47-04:00
```

To check the status of the `folding-at-home` job, run the folliwng command:

```console
nomad status folding-at-home
```

Output will look *something* like this:

```plaintext
ID            = folding-at-home
Name          = folding-at-home
Submit Date   = 2020-07-11T19:36:47-04:00
Type          = service
Priority      = 50
Datacenters   = dc1
Namespace     = default
Status        = running
Periodic      = false
Parameterized = false

Summary
Task Group       Queued  Starting  Running  Failed  Complete  Lost
folding-at-home  0       0         1        0       0         0

Latest Deployment
ID          = 811df760
Status      = successful
Description = Deployment completed successfully

Deployed
Task Group       Desired  Placed  Healthy  Unhealthy  Progress Deadline
folding-at-home  1        1       1        0          2020-07-11T23:47:06Z

Allocations
ID        Node ID   Task Group       Version  Desired  Status   Created   Modified
6311f4ea  fab91380  folding-at-home  0        run      running  3m4s ago  2m45s ago
```

☝🏽We can see in the output from the last command a `Allocations` section with an ID (in this case `6311f4ea`). We can use this allocation ID to interact with the container.

To tail/follow the logs (STDOUT, by default) of the container:

```console
nomad alloc logs -f 6311f4ea
```

> ℹ️ **Note**
>
> Press [CTRL+C](https://en.wikipedia.org/wiki/Control-C) to quit tailing/following the logs.


### Stop Container

To stop the container, we can stop the `folding-at-home` job:

```console
nomad job stop folding-at-home
```

Output will look *something* like this:

```plaintext
==> Monitoring evaluation "b6144971"
    Evaluation triggered by job "folding-at-home"
    Evaluation within deployment: "811df760"
    Evaluation status changed: "pending" -> "complete"
==> Evaluation "b6144971" finished with status "complete"
```

## Doing More with Nomad

Ready to start running other containers in the cluster, or interested in what other things Nomad can do? Check out these awesome resources:

### HashiCorp Learn

The official [HashiCorp Learn](https://learn.hashicorp.com/) platform provides tutorials for:

* [Gettings Started with Jobs](https://learn.hashicorp.com/nomad/getting-started/jobs)
* [ACL System Fundamentlas](https://learn.hashicorp.com/nomad/acls/fundamentals)
* [Advanced Scheduling](https://learn.hashicorp.com/nomad/advanced-scheduling/advanced-scheduling)
* [Stateful Workloads](https://learn.hashicorp.com/nomad/stateful-workloads/stateful-workloads)
* [Task Depencies](https://learn.hashicorp.com/nomad/task-deps/interjob)
* And much [more](https://learn.hashicorp.com/nomad)!

### Documentation

* [Schedulers](https://www.nomadproject.io/docs/schedulers)
* [Job Specification](https://www.nomadproject.io/docs/job-specification)
* [Security Model](https://www.nomadproject.io/docs/internals/security)
* And much [more](https://www.nomadproject.io/docs)!

### Example Job Files

* [Charlie Voiselle's Collection of Nomad Job Examples](https://github.com/angrycub/nomad_example_jobs)
* [Guy Barros' Collection of Nomad Jobs](https://github.com/GuyBarros/nomad_jobs)

## Conclusion

👏🏽 You have now deployed a Nomad cluster, bootstrapped the ACL system with a management token, and submitted an example job using a Docker container, yay!

### Destroy Infrastructure

Once you are done [playing around with Nomad](https://learn.hashicorp.com/nomad), and wish to destroy the infrastructure to save costs, run the following command:

```console
terraform destroy -auto-approve -var="project=$GOOGLE_PROJECT" -var="credentials=$GOOGLE_APPLICATION_CREDENTIALS"
```
