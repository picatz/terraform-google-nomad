#!/bin/bash

# Check if the gcloud command-line tool is installed
if ! command -v gcloud; then
    echo "Install the Google Cloud SDK before using this script:"
    echo "https://cloud.google.com/sdk/"
    exit 1
fi

# Check if a project name was given at the command-line as the first argument
if [ $# -eq 0 ];then
    echo "No project name given"
    exit 1
fi

# If no google organization is set, determine it.
if [ -z "$GOOGLE_ORGANIZATION" ]; then
    # Attempt to auto-determine the organization, if there is only 1
    if [ `gcloud organizations list | grep -v "DISPLAY_NAME" | wc -l` = 1 ]; then
        GOOGLE_ORGANIZATION=`gcloud organizations list | grep -v "DISPLAY_NAME" | awk '{print $2}'`
        echo "Automatically determined organization $GOOGLE_ORGANIZATION"
    else
        gcloud organizations list
        echo -e "\nFrom the list above, choose the correct orgnaization ID and set it as the GOOGLE_ORGANIZATION environment variable to continue!\n"
        exit 1
    fi
fi

# If no google billing account is set, determine it.
if [ -z "$GOOGLE_BILLING_ACCOUNT" ]; then
    # Attempt to auto-determine the organization, if there is only 1
    if [ `gcloud alpha billing accounts list | grep -v "ACCOUNT_ID" | wc -l` = 1 ]; then
        GOOGLE_BILLING_ACCOUNT=`gcloud alpha billing accounts list | grep -v "ACCOUNT_ID" | awk '{print $1}'`
        echo "Automatically determined billing account $GOOGLE_BILLING_ACCOUNT"
    else
        gcloud alpha billing accounts list
        echo -e "\nFrom the list above, choose the correct billing account ID and set it as the GOOGLE_BILLING_ACCOUNT environment variable to continue!\n"
        exit 1
    fi
fi

# Skip project creation if it already exists and we're just bootstrapping it.
if gcloud projects list | grep -v "PROJECT_ID" | grep -q "$1"; then
    # we good
    echo -e "Project '$1' already exists, skipping creation!"
else
    # create the project
    gcloud projects create "$1" --organization="$GOOGLE_ORGANIZATION"
    # now we good
fi

# Set gcloud config to use the given project
gcloud config set project "$1"

# Skip billing account linking if it already exists and we're just bootstrapping it.
if gcloud alpha billing projects list --billing-account "$GOOGLE_BILLING_ACCOUNT" | grep -v "PROJECT_ID" | grep -q "$1"; then
    # we good
    echo -e "Project '$1' billing already exists, skipping linking!"
else
    echo "Setting up '$1' with billing account $GOOGLE_BILLING_ACCOUNT"
    # create the project
    gcloud alpha billing projects link "$1" --billing-account "$GOOGLE_BILLING_ACCOUNT"
    # now we good
fi

echo "Enabling compute engine API for project"
# Enable the compute engine API
gcloud services enable compute.googleapis.com

echo "Creating the Terraform service account"
# Create the service account with account.json file if it doesn't exist
gcloud iam service-accounts create terraform \
    --display-name "Terraform Service Account" \
    --description "Service account to use with Terraform"

echo "Adding the required IAM policy binding for the Terraform service account"
gcloud projects add-iam-policy-binding "$1" \
  --member serviceAccount:"terraform@$1.iam.gserviceaccount.com" \
  --role roles/editor

echo "Creating the required IAM service policy key 'account.json'"
gcloud iam service-accounts keys create account.json \
    --iam-account "terraform@$1.iam.gserviceaccount.com"