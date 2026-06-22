📑 Production Blueprint: Enterprise HL7v2 to FHIR R4 Pipeline

This repository contains the end-to-end implementation framework for an asynchronous, production-grade healthcare data harmonization pipeline. The architecture ingests real-time HL7v2 clinical feeds, executes custom schema transformations, and streams compliant resources into a protected FHIR R4 data store.
🚀 Phase 1: Architecture, Requirements & Governance

Focusing on non-functional requirements, technical scoping, and structural blueprinting.
1. Technical Requirements Specifications

To guarantee reliable data orchestration across distributed clinical endpoints, the pipeline satisfies the following operational criteria:

    Availability Target: Zero-downtime stream ingestion utilizing a highly available managed pub/sub broker to absorb variable transactional loads without dropping source packets.

    Security Perimeter: Strict compliance with healthcare data processing standards through multi-tenant isolation, principle of least privilege (PoLP) service accounts, and dedicated encryption vectors.

    Data Integrity & Traceability: Full diagnostic audit trails capturing lifecycle state transitions from original raw segments down to finalized resource insertions.

2. Infrastructure Graph

The technical architecture decouples message ingestion, processing compute, and the persistent data tier to handle highly transactional workloads:

[HL7v2 Clinical Endpoint] 
       │ (MLLP / HTTPS Feed)
       ▼
[Cloud Ingestion Topic] ────► [Dead Letter Queue (DLQ)]
       │
       ▼ (Pull Streaming Subscription)
[Dataflow Execution Cluster] ◄──── [Secure Storage Bucket] 
       │                               (Whistle Mapping Configs)
       ▼ (REST / FHIR JSON)
[Target FHIR R4 Store] ────► [Cloud Logging & Auditing Workspace]

🛠️ Phase 2: Core Data Harmonization & Engine Configuration

Focusing on data mapping execution, validation schemas, and runtime compilation.
1. Data Schema Mapping

Data mapping uses the Whistle Data Harmonization Language to programmatically convert structural HL7v2 message structures (e.g., ADT, ORU) into standard FHIR R4 schemas.
Code snippet

// Sample Segment Mapping Concept: HL7v2 PID to FHIR Patient Resource
package hl7_to_fhir_r4

def MapPatient(PID) {
  resourceType: "Patient"
  id: PID.3.1
  identifier: MapIdentifiers(PID.3)
  name: MapNames(PID.5)
  gender: MapGender(PID.8)
}

2. Stream Ingestion Subsystem

The engine processes streaming records via decoupling brokers. The underlying ingestion tier is initialized with standard configurations:
Bash

# Explicit registration of the stream subscription interface
gcloud pubsub subscriptions create dev-hl7v2-ingest-topic-sub \
    --topic=dev-hl7v2-ingest-topic \
    --ack-deadline=60

🔒 Phase 3: Enterprise Security Perimeters & Observability

Focusing on Identity & Access Management (IAM), runtime worker isolation, and audit structures.
1. RBAC & IAM Least Privilege Configuration

To maintain strict administrative barriers, standard system-generated identities are blocked. Operations are bound to a restricted, custom-scoped service identity (df-worker-sa):
Bash

# 1. Restrict bucket scope exclusively to Object Administration privileges
gcloud storage buckets add-iam-policy-binding gs://healthcare-dev-497314-mapping-configs \
    --member="serviceAccount:df-worker-sa@healthcare-dev-497314.iam.gserviceaccount.com" \
    --role="roles/storage.objectAdmin"

# 2. Grant minimum required operational execution rights for the data processor
gcloud projects add-iam-policy-binding healthcare-dev-497314 \
    --member="serviceAccount:df-worker-sa@healthcare-dev-497314.iam.gserviceaccount.com" \
    --role="roles/dataflow.worker"

2. Production Deployment Sequence

The application compiles dependency layers locally into an isolated execution unit, bypassing insecure public registries or unpinned templates to maintain configuration consistency:
Bash

# Step 1: Initialize local environment wrapper
gradle wrapper --gradle-version 7.6

# Step 2: Compile isolated shadow archive containing necessary class definitions
./gradlew shadowJar

# Step 3: Run pipeline with strict worker account impersonation
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

3. Observability & Data Validation Check

Data delivery is verified directly at the API gateway layer using secure cryptographic token impersonation to confirm the successful conversion of downstream structures:
Bash

# Generate localized authorization token and query specific patient records
APP_TOKEN=$(gcloud auth print-access-token --impersonate-service-account=dev-app-sa@healthcare-dev-497314.iam.gserviceaccount.com)

curl -X GET \
  -H "Authorization: Bearer ${APP_TOKEN}" \
  -H "Content-Type: application/fhir+json" \
  "https://healthcare.googleapis.com/v1/projects/healthcare-dev-497314/locations/us-central1/datasets/dev-clinical-dataset/fhirStores/dev-fhir-core-store/fhir/Patient?family=BEEBLEBROX"
