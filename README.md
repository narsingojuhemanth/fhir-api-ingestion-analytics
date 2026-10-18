# FHIR API Ingestion & Analytics

Assessment project using Microsoft Fabric and the public HAPI FHIR R4 API.

## Project status

- [x] Environment selected: Microsoft Fabric
- [x] Workspace created: `ws_fhir_assessment`
- [x] Lakehouse created: `lh_fhir_assignment`
- [x] Spark notebook created: `nb_01_fhir_ingestion`
- [x] Spark environment smoke test passed
- [x] GitHub repository and project scaffold created
- [x] HAPI FHIR R4 connectivity checked for Patient, Encounter, Observation, and Condition
- [x] Patient pagination tested by following the API-provided `next` link
- [ ] Reusable ingestion for all four resources
- [ ] Raw and Bronze layers
- [ ] Incremental ingestion across 2–3 days and SCD Type 2 history
- [ ] Silver and Gold layers
- [ ] Orchestration pipeline
- [ ] End-to-end validation and final documentation

## Assignment requirements

Use Spark notebooks to fetch data incrementally over 2–3 days using pagination. Preserve the original JSON/XML API responses in date-bucketed, resource-specific Raw folders. Convert responses into Delta/Parquet in Bronze and capture `extraction_timestamp` and `api_url_or_params`. Track when each API was called and when data was saved. Detect changes between daily loads and retain historical versions using SCD Type 2.

Build Raw → Bronze → Silver → Gold. In Silver, clean and deduplicate using Spark or Dataflows Gen2. Dataflows Gen2 must not be used for JSON-to-table conversion. Gold should provide final warehouse views optimized for reporting and analytics.

Orchestration must run in this order: Patient → Encounter → Observation → Condition, handling transformation, metadata logging and data loading. Code should be modular and reusable, without hardcoding. Submit all code, notebooks, pipeline setup, and clear documentation of pipeline/table relationships via a Git repository or ZIP.

## Source

HAPI FHIR R4: https://hapi.fhir.org/baseR4/swagger-ui/

## Project structure

```text
docs/                 # Architecture, data dictionary, table relationships, runbook
notebooks/            # Exported Fabric notebook source
src/                  # Reusable ingestion and transformation modules, where applicable
pipelines/             # Pipeline setup and recreation instructions
tests/                 # Validation queries and test evidence
```

## Data and security notes

- Do not commit credentials, tokens, or secrets.
- Do not commit raw FHIR payloads or other data extracts to this repository.
- Keep Fabric runtime data in the Lakehouse; store code and documentation in Git.
- Optional extensions after required scope: XML ingestion and a one-page Power BI report.
