# Assignment Requirement Traceability

This matrix follows the wording of the supplied three-page FHIR API Data Ingestion & Analytics Assignment.

| Requirement from assignment | Project implementation | Final deployment evidence to collect |
|---|---|---|
| Access to Fabric or Databricks | Microsoft Fabric workspace and schema-enabled Lakehouse | Workspace/Lakehouse exist |
| Use public HAPI FHIR R4 API | Ingestion notebook calls the public baseR4 endpoints | Successful HTTP responses for all resources |
| Ingest Patient, Encounter, Observation, Condition | Same parameterized ingestion notebook, called once per resource in pipeline | Audit shows successful runs for all four resource types |
| Fetch incrementally for 2–3 days using pagination | Initial three-day lookback, persisted source watermark, overlap, server-provided next links | Successful pipeline runs on separate days and page/audit evidence |
| Store JSON response as-is in Lakehouse | Original response bytes saved under Raw; metadata is in separate sidecar | Raw files exist by resource/date/run |
| Convert API responses into Delta/Parquet in Bronze | One schema-based Bronze Delta table per resource | Four Bronze tables and counts |
| Add extraction_timestamp and api_url_or_params | Both columns in Bronze and page metadata/audit | No null metadata values for successfully ingested resources |
| Track when each API was called and when data was saved | Audit table and sidecar timestamps | Audit rows include call and save times |
| Detect daily changes and preserve history with SCD Type 2 | Content hashes in Bronze; version history in Silver with valid_from, valid_to, is_current | Changed resource across runs has multiple Silver versions; exactly one is current |
| Raw responses bucketed by date with folders for API objects | Resource/extraction-date/run-ID folder structure | Inspect Raw folders |
| Silver cleaning and deduplication | Spark transformations in Silver notebook | Silver current-row and interval validation |
| Dataflows Gen2 only for transformations, not JSON conversion | Spark performs JSON-to-table conversion; no Dataflows Gen2 used for parsing | Review notebook implementation |
| Gold final Warehouse views optimized for reporting | Gold Delta tables plus Warehouse SQL views over Gold | Query all four Warehouse views |
| Orchestrate Patient → Encounter → Observation → Condition | Six-stage Fabric Data Pipeline, with those four calls first | Pipeline dependency order and successful run |
| Handle transformation, metadata logging, and data loading | Ingestion audit/watermark logging and Silver/Gold notebook stages | Pipeline run history and control tables |
| Modular reusable code with no hardcoding | Parameterized ingestion notebook reused for all four resources | Four activity parameter settings |
| Submit code, notebooks, pipeline setup | This repository | Repository link or ZIP |
| Document pipeline and table relationships | Architecture, data dictionary, lineage, pipeline runbook | Check files under docs/ and pipelines/ |

## Optional extensions (not part of required scope)

- XML ingestion in addition to JSON.
- One-page Power BI report sourced from Gold.

These remain optional and should not delay the mandatory requirements.

## Acceptance condition

Source code in GitHub is not proof of runtime success. Execute the updated notebooks in the new Fabric workspace, capture the pipeline and table validation output, retain successful run evidence across 2–3 days, and demonstrate historical versions when changed source content is observed.
