#!/bin/bash

# Stream Ingestion Subsystem Initialization
gcloud pubsub subscriptions create dev-hl7v2-ingest-topic-sub \
    --topic=dev-hl7v2-ingest-topic \
    --ack-deadline=60

# Local Environment Wrapper & Shadow Compilation
gradle wrapper --gradle-version 7.6
./gradlew shadowJar

# Execution with Worker Impersonation
java -jar build/libs/converter-0.1.0-all.jar \
  --project=healthcare-dev-497314 \
  --region=us-central1 \
  --runner=DataflowRunner \
  --jobName=hl7-to-fhir-streaming-job \
  --serviceAccount=df-worker-sa@healthcare-dev-497314.iam.gserviceaccount.com \
  --gcpTempLocation=gs://healthcare-dev-497314-mapping-configs/tmp/ \
  --pubSubSubscription=projects/healthcare-dev-497314/subscriptions/dev-hl7v2-ingest-topic-sub \
  --fhirStore=projects/healthcare-dev-497314/locations/us-central1/datasets/dev-clinical-dataset/fhirStores/dev-fhir-core-store \
  --mappingPath=gs://healthcare-dev-497314-mapping-configs/hl7v2_fhir_r4/hl7v2_fhir_r4.wsl

# Observability & Validation Query
APP_TOKEN=$(gcloud auth print-access-token --impersonate-service-account=dev-app-sa@healthcare-dev-497314.iam.gserviceaccount.com)

curl -X GET \
  -H "Authorization: Bearer ${APP_TOKEN}" \
  -H "Content-Type: application/fhir+json" \
  "https://healthcare.googleapis.com/v1/projects/healthcare-dev-497314/locations/us-central1/datasets/dev-clinical-dataset/fhirStores/dev-fhir-core-store/fhir/Patient?family=BEEBLEBROX"
