# Assignment Requirement Traceability

This matrix maps the supplied *FHIR API Data Ingestion & Analytics Assignment* to the project implementation. “Packaged” means source/documentation exists in Git; “Runtime pending” means it must still be executed and evidenced in Fabric.

| Assignment requirement | Implementation location | Status |
|---|---|---|
| Use public HAPI FHIR R4 API | `notebooks/nb_01_fhir_ingestion.ipynb` | Packaged; basic API checks passed manually |
| Ingest Patient | Ingestion notebook parameter `resource_type=Patient` | Runtime pending in clean workspace |
| Ingest Encounter | Same parameterized ingestion notebook, pipeline activity overrides resource type | Runtime pending |
| Ingest Observation | Same parameterized ingestion notebook, pipeline activity overrides resource type | Runtime pending |
| Ingest Condition | Same parameterized ingestion notebook, pipeline activity overrides resource type | Runtime pending |
| Spark notebook pagination | Ingestion notebook follows Bundle `next` URL and enforces `max_pages` safety limit | Packaged; Patient pagination test passed, full pipeline pending |
| Incremental ingestion for 2–3 days | `_lastUpdated=ge...`, persisted per-resource watermark and overlap; see pipeline runbook | Code packaged; successful runs across 2–3 days pending |
| Store original JSON/XML response as-is in Lakehouse | Successful response body written to Raw as bytes; JSON is required scope | JSON packaged; Fabric runtime pending; XML optional |
| Convert responses to Delta/Parquet in Bronze | `bronze.<Resource>` Delta tables | Packaged; runtime pending |
| Required metadata `extraction_timestamp`, `api_url_or_params` | Bronze schema and Raw sidecars | Packaged; runtime pending |
| Track API-call and saved times | `dbo.fhir_ingestion_audit` and page metadata sidecars | Packaged; runtime pending |
| Detect changes across loads | `content_hash` and Bronze Delta MERGE | Packaged; runtime pending |
| Retain SCD Type 2 history | `notebooks/nb_02_silver_scd2.ipynb`, `valid_from`, `valid_to`, `is_current` | Packaged; actual version-change proof pending |
| Raw date-bucketed and resource-organized folders | `Files/raw/fhir/resource=.../extraction_date=.../run_id=...` | Packaged; runtime pending |
| Silver cleaning/deduplication | Silver notebook using Spark | Packaged; runtime pending |
| Do not use Dataflows Gen2 for JSON-to-table conversion | JSON parsing and conversion are in Spark notebooks | Compliant by design |
| Gold warehouse views optimized for reporting | Gold Delta tables and `warehouse/create_gold_views.sql` | Packaged; Warehouse views still need to be created and queried in Fabric |
| Pipeline call order Patient → Encounter → Observation → Condition | `pipelines/fabric_pipeline_setup.md` | Setup instructions packaged; pipeline exists but needs updated notebook sources and an end-to-end run |
| Orchestrate transformation, metadata logging and loading | Ingestion audit/watermark; Silver/Gold notebooks; SQL Warehouse views | Pipeline setup documented; end-to-end run pending |
| Modular reusable code, no hardcoding | One parameterized ingestion notebook reused for all four resources | Packaged; runtime pending |
| Submit all code and notebooks | GitHub repository and `notebooks/*.ipynb` | Source packaged |
| Include pipeline setup | `pipelines/fabric_pipeline_setup.md` | Documentation packaged; live pipeline must be created in Fabric |
| Document pipeline and table relationships | `docs/pipeline_table_relationships.md`, `docs/data_dictionary.md`, `docs/architecture.md` | Packaged |
| Optional XML ingestion | Not implemented | Optional, defer until mandatory scope passes |
| Optional one-page Power BI report | Not implemented | Optional, defer until mandatory scope passes |

## Additional workspace setup artifacts

- The importable package includes `nb_00_setup_cleanup.ipynb`. It is guarded by a reset token and must be run manually only; it must never be placed in the daily pipeline.
- The ingestion notebook has a safe bootstrap cell to ensure schemas exist and remove old prefixed tables only when matching schema-based replacements are present.
- The validation notebook `nb_04_validation.ipynb` is read-only and produces cross-layer quality evidence.

## What counts as completion

Do not treat source files alone as proof of end-to-end completion. Before submission, run `tests/acceptance_checklist.md`, capture successful Fabric pipeline runs, verify tables and Warehouse views, and retain audit evidence across the required 2–3-day period.
