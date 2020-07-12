# Deploy a Nomad Cluster to GCP

## Welcome!

👩🏽‍💻This tutorial will teach you how to deploy [Nomad](https://www.nomadproject.io/) clusters to the Google Cloud Platform using [Packer](https://www.packer.io/) and [Terraform](https://www.terraform.io/)!

**Includes**:

1. 🛠 Setting up your cloud shell environment with `packer` and `terraform` binaries.
2. ⚙️  Configuring a new GCP project, linking the billing account, and enabling the compute engine API using `gcloud`.
3. 📦 Packaging cluster golden images (bastion, server, and client) with `packer`.
4. ☁️  Deploying a Nomad cluster using `terraform`.
5. 🔐 Bootstrapping the [ACL system](https://learn.hashicorp.com/nomad/acls/fundamentals), obtaining a administrative management token.
6. 🐳 Submitting an example job as a Docker container running [Folding at Home](https://foldingathome.org/) to the cluster, tailing the logs, and then stopping the container.

## Setup Environment

Before we can deploy our cluster to GCP, we need to first setup our environment with the required tools.

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

🎉 Now we have installed `nomad`, `packer`, and `terraform`!

Next, let's configure out GCP project to ensure it's ready for us to deploy our cluster.

## Configure Project

Before building our infrastructure, we'll need to do a few things:

1. Create a new GCP project.
2. Link a billing account to that project.
3. Enable the compute engine API.
4. Create a Terraform Service Account, with a credentials file (`account.json`).
5. Set the required environment variables.

### Create a New Project

To get started, let's create a new GCP project:

```console
gcloud projects create your-new-project-name
```
> ℹ️  **Projects within GSuite Organizations**
>
> If you have any organizations associated with your account, which is likely that case if you're an student or an employee at an organization using GSuite, then you can create a new project within that organization:
>
> ```console
> gcloud project create your-new-project-name --organization="$GOOGLE_ORGANIZATION"
> ```
>
> To find out what organization display name to use for `GOOGLE_ORGANIZATION`, run the following command:
>
> ```console
> gcloud organizations list
> ```

### Link Billing Account to Project

Next, let's link a billing account to that project which can now be set as an environment variable:

```console
export GOOGLE_PROJECT="your-new-project-name"
```

And then set your `gcloud` config to use that project:

```console
gcloud config set project $GOOGLE_PROJECT
```

To determine what billing accounts are available:

```console
gcloud alpha billing accounts list
```

Then set the preferred billing account ID:

```console
export GOOGLE_BILLING_ACCOUNT="XXXXXXX"
```

Now we can link the `GOOGLE_BILLING_ACCOUNT` with the `GOOGLE_PROJECT`:

```console
gcloud alpha billing projects link "$GOOGLE_PROJECT" --billing-account "$GOOGLE_BILLING_ACCOUNT"
```

### Enable Compute API

To deploy VMs to the project, we need to enable the compute API:

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

Now set the *full path* of the newly created `account.json` file as `GOOGLE_APPLICATION_CREDENTIALS` environment variable.

```console
export GOOGLE_APPLICATION_CREDENTIALS=$(realpath account.json)
```

### Ensure Required Environment Variables Are Set

Before moving onto the next steps, be sure that the following environment variables are set:

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

Once the command completes successfully, change back to the root directory of the repository (going back/up one directory) to move onto the next phase:

```console
cd ..
```

## Deploy Infrastructure with Terraform

🙌🏽 Now to finally deploy the Nomad cluster!

### Initialize Terraform

Change into the `example` directory and initialize Terraform:

```console
cd example
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

### Run Container

Now that we deployed the cluster, let's use it to run an example job, a Docker container that runs Folding at Home:

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

## Conclusion

👏🏽 You have now deployed a Nomad cluster, bootstrapped the ACL system with a management token, and submitted an example job using a Docker container, yay!

### Destroy Infrastructure

Once you are done [playing around with Nomad](https://learn.hashicorp.com/nomad), and wish to destroy the infrastructure to save costs, run the following command:

```console
terraform destroy -auto-approve -var="project=$GOOGLE_PROJECT" -var="credentials=$GOOGLE_APPLICATION_CREDENTIALS"
```
