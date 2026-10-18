# FHIR API Ingestion & Analytics

Assessment project using Microsoft Fabric and the public HAPI FHIR R4 API.

## Current status

### Setup and source discovery
- [x] Microsoft Fabric selected.
- [x] Workspace: `ws_fhir_assessment`.
- [x] Lakehouse: `lh_fhir_assignment`.
- [x] Spark environment smoke test passed.
- [x] GitHub repository and project scaffold created.
- [x] Connectivity checked for Patient, Encounter, Observation, and Condition.
- [x] Patient pagination tested by following the server-provided `next` link.
- [x] First-page `_lastUpdated=ge...` filter test passed for all four resource endpoints.

### Implementation package
- [x] Parameterized Raw + Bronze ingestion notebook source added.
- [x] Silver SCD Type 2 transformation notebook source added.
- [x] Gold analytics table notebook source added.
- [x] Warehouse SQL views script added.
- [x] Architecture, data dictionary, lineage, pipeline setup, traceability matrix, and validation checklist added.

### Fabric runtime progress
- [x] Ingestion notebook imported and attached to `lh_fhir_assignment`.
- [x] Patient ingestion succeeded: run `20261018T091904061761Z`; 8 pages; 711 resource records observed.
- [x] Patient Bronze validation passed: 711 rows and 711 distinct IDs; zero missing resource IDs, JSON, hashes, extraction timestamps, request URLs, or save timestamps.
- [x] Patient audit validation passed: 8 page rows, each HTTP 200, RAW_SAVED, SUCCESS.
- [x] Patient source watermark was persisted.
- [ ] Run and validate ingestion for Encounter, Observation, and Condition.
- [ ] Run and validate Silver SCD Type 2.
- [ ] Run and validate Gold analytics tables.
- [ ] Create `wh_fhir_assignment`, copy Gold tables, and create Warehouse views.
- [ ] Create and run `pl_fhir_assessment` end-to-end.
- [ ] Retain successful run evidence across 2–3 days.
- [ ] Export final Fabric notebook source, create ZIP backup, and verify submission package.

**Important:** Notebook source and setup documentation are packaged in GitHub. Patient ingestion and its immediate metadata checks passed in Fabric. The full end-to-end implementation has not yet been executed or validated; do not mark remaining runtime requirements complete until those checks pass.

## Architecture

```text
HAPI FHIR R4 API
  Patient → Encounter → Observation → Condition
                   |
                   v
Raw: original response bodies + metadata sidecars
                   |
                   v
Bronze: Delta tables + content hash + audit + watermark
                   |
                   v
Silver: clean/deduplicated SCD Type 2 version history
                   |
                   v
Gold: analytics-ready current-state Delta tables
                   |
                   v
Fabric Warehouse: dbo.vw_gold_* reporting views
```

## Assignment requirements

Use Spark notebooks to fetch data incrementally over 2–3 days using pagination. Preserve original JSON/XML API responses in date-bucketed, resource-specific Raw folders. Convert responses into Delta/Parquet in Bronze and capture `extraction_timestamp` and `api_url_or_params`. Track when each API is called and when data is saved. Detect changes between daily loads and retain historical versions using SCD Type 2.

Build Raw → Bronze → Silver → Gold. In Silver, clean and deduplicate data using Spark or Dataflows Gen2. Dataflows Gen2 must not be used for JSON-to-table conversion. Gold should provide final warehouse views optimized for reporting and analytics.

Orchestration must run in this order: Patient → Encounter → Observation → Condition, handling transformation, metadata logging and data loading. Code should be modular and reusable, without hardcoding. Submit all code, notebooks, pipeline setup, and clear documentation of pipeline/table relationships via a Git repository link or ZIP.

## Source

HAPI FHIR R4: https://hapi.fhir.org/baseR4/swagger-ui/

## Repository structure

- `notebooks/` — importable Jupyter notebook files for Fabric.
- `warehouse/` — SQL to create final Warehouse views.
- `docs/` — architecture, data dictionary, requirement traceability, and lineage.
- `pipelines/` — Fabric Data Pipeline setup runbook.
- `tests/` — validation queries and acceptance checklist.
- `src/` — placeholder for reusable modules if the implementation evolves beyond notebooks.

## Data handling

- Do not commit credentials, tokens, secrets, Raw payloads, or extracted datasets.
- Keep project code and documentation in Git; keep runtime data in the Lakehouse/Warehouse.
- The first incremental-filter test checked only the first page for each resource; full pagination and incremental behavior still need end-to-end validation.
- XML ingestion and a one-page Power BI report are optional extensions after mandatory scope passes.
