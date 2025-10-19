#!/bin/bash

echo "NOTE: Validating credentials.json and test the gcloud command"

# Check if the file "./credentials.json" exists
if [[ ! -f "./credentials.json" ]]; then
  echo "ERROR: The file './credentials.json' does not exist." >&2
  exit 1
fi

gcloud auth activate-service-account --key-file="./credentials.json"

# Extract the project_id using jq
project_id=$(jq -r '.project_id' "./credentials.json")

echo "NOTE: Enabling APIs needed for build."

gcloud config set project $project_id  
gcloud services enable compute.googleapis.com --quiet
gcloud services enable storage.googleapis.com --quiet
gcloud services enable dns.googleapis.com --quiet
gcloud services enable certificatemanager.googleapis.com --quiet
gcloud services enable cloudresourcemanager.googleapis.com --quiet
gcloud services enable serviceusage.googleapis.com --quiet


