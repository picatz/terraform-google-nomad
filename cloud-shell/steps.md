# Deploy a Nomad Cluster to GCP

## Welcome!

👩🏽‍💻This tutorial will teach you how to deploy [Nomad](https://www.nomadproject.io/) clusters to the Google Cloud Platform using [Packer](https://www.packer.io/) and [Terraform](https://www.terraform.io/)!

**Includes**:

1. 🛠 Setting up your cloud shell environment with `packer` and `terraform` binaries.
2. ⚙️  Configuring a new GCP project, linking the billing account, and enabling the compute engine API using `gcloud`.
3. 📦 Packaging cluster golden images (bastion, server, and client) with `packer`.
4. ☁️  Deploying a Nomad cluster using `terraform`.

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

Once the command completes successfully, change back to the root directory (going back/up one directory) to move onto the next phase:

```console
cd ..
```

## Deploy Infrastructure with Terraform

Now to finally deploy the Nomad cluster!

Change into the `example` directory and initialize Terraform:

```console
cd example
terraform init
```

To plan our infrastructure changes, use `terraform plan`:

```console
terraform plan -var="project=$GOOGLE_PROJECT" -var="credentials=$GOOGLE_APPLICATION_CREDENTIALS"
```

To apply the changes, actually creating the cluster:

```console
terraform apply -var="project=$GOOGLE_PROJECT" -var="credentials=$GOOGLE_APPLICATION_CREDENTIALS"
```

> ℹ️ **Note**
>
> The command will take about 5 minutes to complete.

### Set Environment Variables


## Conclusion

👏🏽 You have now deployed a Nomad cluster, yay!

### Destroy Infrastructure

Once you are done playing around with Nomad, and wish to destroy the infrastructure to save costs, run the following command:

```console
terraform destroy -var="project=$GOOGLE_PROJECT" -var="credentials=$GOOGLE_APPLICATION_CREDENTIALS"
```
