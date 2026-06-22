#!/bin/bash
# 1. Restrict bucket scope exclusively to Object Administration privileges
gcloud storage buckets add-iam-policy-binding gs://healthcare-dev-497314-mapping-configs \
    --member="serviceAccount:df-worker-sa@healthcare-dev-497314.iam.gserviceaccount.com" \
    --role="roles/storage.objectAdmin"

# 2. Grant minimum required operational execution rights for the data processor
gcloud projects add-iam-policy-binding healthcare-dev-497314 \
    --member="serviceAccount:df-worker-sa@healthcare-dev-497314.iam.gserviceaccount.com" \
    --role="roles/dataflow.worker"
