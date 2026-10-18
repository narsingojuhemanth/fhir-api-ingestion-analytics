# FHIR API Ingestion & Analytics

Assessment project using Microsoft Fabric and the public HAPI FHIR R4 API.

## Project status

- [x] Environment selected: Microsoft Fabric
- [x] Workspace created: `ws_fhir_assessment`
- [x] Lakehouse created: `lh_fhir_assignment`
- [x] Spark notebook created: `nb_01_fhir_ingestion`
- [x] Spark environment smoke test passed (Spark 4.1.1.5.5.20260930.238388267)
- [x] GitHub repository created and project scaffold committed
- [ ] FHIR API behavior and pagination understood and validated
- [ ] Reusable ingestion for Patient, Encounter, Observation, Condition
- [ ] Raw and Bronze layers
- [ ] Incremental ingestion and SCD Type 2 history
- [ ] Silver and Gold layers
- [ ] Orchestration pipeline
- [ ] End-to-end validation and final documentation

## Assignment requirements

The solution will use Spark notebooks to fetch data incrementally over 2–3 days with pagination, preserve original JSON/XML API responses in dated Raw folders, convert responses to Delta/Parquet in Bronze, and capture extraction and API request metadata. It will track API-call and save times, detect changes across daily loads, and retain history using SCD Type 2. Silver will clean and deduplicate data using Spark or Dataflows Gen2 (Dataflows Gen2 will not be used for JSON-to-table conversion). Gold will provide warehouse views for analytics.

The orchestration must run in this order: Patient → Encounter → Observation → Condition. The final delivery will include all code, notebooks, pipeline setup, and documentation of pipeline/table relationships.

## Source

HAPI FHIR R4: https://hapi.fhir.org/baseR4/swagger-ui/

## Project structure

```text
docs/                 # Architecture, data dictionary, pipeline relationships, runbook
notebooks/            # Exported Fabric notebook source
src/                  # Reusable ingestion and transformation modules, where applicable
pipelines/            # Pipeline setup and recreation instructions
tests/                # Validation queries and test evidence
```

## Data and security notes

- Do not commit credentials, tokens, or secrets.
- Do not commit raw FHIR payloads or other data extracts to this repository.
- Keep Fabric runtime data in the Lakehouse; store code and documentation in Git.
- Optional extensions after the required scope: XML ingestion and a one-page Power BI report.
