#!/bin/bash
# ============================================================================================
# FILE: wait-for-cert.sh
# PURPOSE:
#   Wait until a Google-managed SSL certificate becomes ACTIVE.
#   Polls every 60 seconds and exits once both domains are validated.
# ============================================================================================

set -euo pipefail

CERT_NAME="website-cert"   # Change if needed
PROJECT_ID="$(gcloud config get-value project 2>/dev/null || true)"

echo "NOTE: Monitoring certificate status for: ${CERT_NAME}"
echo "NOTE: Project: ${PROJECT_ID}"

while true; do
  STATUS=$(gcloud compute ssl-certificates describe "$CERT_NAME" --global \
            --format="value(managed.status)" 2>/dev/null || echo "UNKNOWN")

  DOMAIN_STATUSES=$(gcloud compute ssl-certificates describe "$CERT_NAME" --global \
            --format="value(managed.domainStatus)" 2>/dev/null || echo "UNKNOWN")

  echo "NOTE: Certificate status: ${STATUS}"
  echo "NOTE: Domain statuses: ${DOMAIN_STATUSES}"

  if [[ "$STATUS" == "ACTIVE" ]]; then
    echo "NOTE: Certificate is ACTIVE for all domains."
    break
  fi

  if [[ "$STATUS" == "FAILED" || "$STATUS" == "FAILED_NOT_VISIBLE" ]]; then
    echo "ERROR: Certificate failed to provision. Check DNS records and try again."
    exit 1
  fi

  echo "WARNING: Still provisioning. Waiting 300 seconds..."
  sleep 300
done

echo "NOTE: Certificate is now active and HTTPS should be live."

cd ./01-website
DOMAIN=$(terraform console <<< "var.domain_name" | tr -d '"')
cd ..
URL="https://www.${DOMAIN}"
echo "NOTE: URL is now reachable: $URL"
