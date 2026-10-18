# FHIR API Data Ingestion & Analytics

A Microsoft Fabric implementation of the FHIR API Ingestion & Analytics assignment using the public HAPI FHIR R4 API.

## Scope

Required resources: Patient, Encounter, Observation, Condition.

Required layers: Raw → Bronze → Silver → Gold.

Required capabilities: paginated ingestion over 2–3 days, unchanged Raw response storage, Bronze Delta tables, extraction/request metadata, API-call/save-time logging, daily change detection and SCD Type 2 history, Silver cleaning/deduplication, Gold Warehouse views, ordered orchestration, reusable code, and documentation of pipeline/table relationships.

Optional extensions (not included in the required implementation): XML ingestion and a one-page Power BI report.

## Clean deployment from zero

1. Delete the previous assessment workspace yourself in the Fabric portal if you want a genuinely clean start. This repository cannot delete your Fabric workspace.
2. Create a new workspace, for example `ws_fhir_assessment`.
3. Create a **schema-enabled** Lakehouse named `lh_fhir_assignment`. Keep Lakehouse schemas enabled.
4. Create a Fabric Warehouse named `wh_fhir_assignment`.
5. Download this repository from **Code → Download ZIP**. Optional preflight on your computer: from the extracted project root, run `python tests/validate_notebooks.py` to check notebook JSON and Python syntax.
6. Import these notebooks into the workspace:
   - `notebooks/nb_01_fhir_ingestion.ipynb` → item name `nb_01_fhir_ingestion`
   - `notebooks/nb_02_silver_scd2.ipynb` → item name `nb_02_silver_scd2`
   - `notebooks/nb_03_gold_analytics.ipynb` → item name `nb_03_gold_analytics`
   - `notebooks/nb_04_validation.ipynb` → item name `nb_04_validation`
7. Attach `lh_fhir_assignment` as the default Lakehouse for each notebook. In the ingestion notebook, keep the parameter cell marked as the notebook parameter cell.
8. Create the pipeline described in `pipelines/fabric_pipeline_setup.md`.
9. Run the pipeline once, then run it on separate days for the required 2–3-day evidence. Run `nb_04_validation` to inspect table quality and successful audit runs.
10. In `wh_fhir_assignment`, add the Lakehouse SQL analytics endpoint for `lh_fhir_assignment` through **+ Warehouses** and execute `warehouse/create_gold_views.sql`.
11. Before submission, complete `tests/acceptance_checklist.md`.

The ingestion notebook creates the schemas idempotently at startup. It does not contain destructive cleanup logic. In a genuinely new workspace, there are no legacy tables to drop; avoiding destructive code in the recurring pipeline protects the Raw history and SCD Type 2 versions.

## Architecture

```text
HAPI FHIR R4 API
  Patient → Encounter → Observation → Condition
                   |
                   v
Raw: original Bundle responses + metadata sidecars
                   |
                   v
Bronze schema: Patient / Encounter / Observation / Condition
                   |
                   v
Silver schema: cleaned, deduplicated SCD Type 2 versions
                   |
                   v
Gold schema: current-state analytics Delta tables
                   |
                   v
Warehouse wh_fhir_assignment:
  dbo.vw_Patient / dbo.vw_Encounter / dbo.vw_Observation / dbo.vw_Condition
```

Gold remains in the Lakehouse. Warehouse views reference the Gold tables using same-workspace three-part naming, so separate Gold Copy Data activities are not required.

## Repository contents

- `notebooks/` — four importable Fabric notebooks.
- `pipelines/fabric_pipeline_setup.md` — pipeline setup and daily-run instructions.
- `warehouse/create_gold_views.sql` — final Warehouse views.
- `docs/` — architecture, data dictionary, lineage, and requirement traceability.
- `tests/` — acceptance checklist, SQL validation queries, and a static notebook validator.

## Runtime evidence and honesty

This repository packages the source and runbook; it does not contain Fabric runtime data or credentials. End-to-end success must be demonstrated in your new workspace. In particular, retain successful runs on separate days and verify SCD Type 2 history when changed source content is observed. A three-day initial lookback by itself does not prove ingestion ran for 2–3 separate days.

## Security

Do not commit Raw FHIR payloads, extracted data, credentials, or tokens to this public repository. Store source files and documentation in Git; store runtime data in the Lakehouse.
