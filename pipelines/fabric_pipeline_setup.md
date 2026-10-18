# Fabric Data Pipeline Setup

## 1. Create workspace assets

In your new Fabric workspace:
- Create a schema-enabled Lakehouse named `lh_fhir_assignment`.
- Create a Warehouse named `wh_fhir_assignment`.
- Import the four notebook files from `notebooks/` and give them these item names:
  - `nb_01_fhir_ingestion`
  - `nb_02_silver_scd2`
  - `nb_03_gold_analytics`
  - `nb_04_validation`
- Attach `lh_fhir_assignment` as the default Lakehouse to every notebook.

The ingestion notebook creates the `bronze`, `silver`, and `gold` schemas idempotently. There is no destructive reset step in the ingestion path; a new workspace and Lakehouse are the clean start.

## 2. Ingestion notebook parameters

Mark the first configuration code cell in `nb_01_fhir_ingestion` as the notebook parameter cell. Defaults:

| Parameter | Default |
|---|---|
| `resource_type` | `Patient` |
| `initial_lookback_days` | `3` |
| `page_size` | `100` |
| `overlap_minutes` | `5` |
| `max_pages` | `1000` |

Each pipeline activity reuses the same ingestion notebook and overrides only `resource_type`. Other values may use defaults.

## 3. Create pipeline

Create a Fabric Data Pipeline named `pl_fhir_assessment`. Add six Notebook activities, linked sequentially using the green **On success** dependency:

| Order | Activity name | Notebook | Base parameter |
|---:|---|---|---|
| 1 | `Ingest_Patient` | `nb_01_fhir_ingestion` | `resource_type = Patient` |
| 2 | `Ingest_Encounter` | `nb_01_fhir_ingestion` | `resource_type = Encounter` |
| 3 | `Ingest_Observation` | `nb_01_fhir_ingestion` | `resource_type = Observation` |
| 4 | `Ingest_Condition` | `nb_01_fhir_ingestion` | `resource_type = Condition` |
| 5 | `Transform_Silver_SCD2` | `nb_02_silver_scd2` | none |
| 6 | `Build_Gold_Tables` | `nb_03_gold_analytics` | none |

The four API activities must stay in the specified order. Do not add the validation notebook to the production chain; run it separately after a successful pipeline run.

## 4. Table layout and data flow

- Raw response bodies and sidecars: Lakehouse Files under `raw/fhir/resource=.../extraction_date=.../run_id=...`.
- Bronze: `bronze.Patient`, `bronze.Encounter`, `bronze.Observation`, `bronze.Condition`.
- Silver: `silver.Patient`, `silver.Encounter`, `silver.Observation`, `silver.Condition`.
- Gold: `gold.Patient`, `gold.Encounter`, `gold.Observation`, `gold.Condition`.
- Audit: `dbo.fhir_ingestion_audit`.
- Watermarks: `dbo.fhir_ingestion_watermarks`.

Each ingestion activity handles API pagination, Raw persistence, Bronze loading, and metadata logging. Silver transforms all four Bronze tables after all four ingestions finish; Gold builds current-state analytical tables after Silver succeeds.

## 5. Create Warehouse views

Gold remains in the Lakehouse; no Copy Data activities are needed for Gold. After the first successful pipeline run:

1. Open Warehouse `wh_fhir_assignment`.
2. In the SQL editor Explorer, use **+ Warehouses** and add the SQL analytics endpoint for `lh_fhir_assignment`.
3. Execute `warehouse/create_gold_views.sql`.
4. Query each view:
   - `SELECT TOP (20) * FROM dbo.vw_Patient;`
   - `SELECT TOP (20) * FROM dbo.vw_Encounter;`
   - `SELECT TOP (20) * FROM dbo.vw_Observation;`
   - `SELECT TOP (20) * FROM dbo.vw_Condition;`

The Warehouse views reference the Lakehouse Gold tables using same-workspace three-part naming. They refresh logically when Gold is rebuilt; no duplicate Gold table load is required.

## 6. Demonstrate the 2–3-day incremental requirement

- Run the pipeline on day 1.
- Run it again on day 2 and, where feasible, day 3.
- In `dbo.fhir_ingestion_audit`, verify distinct successful run IDs and timestamps for all four resource types.
- Inspect `dbo.fhir_ingestion_watermarks` after each run.
- When an updated FHIR resource is returned, verify its content hash is retained in Bronze and that Silver keeps the historical version with one current version.

The first-run three-day lookback alone does not demonstrate separate daily runs. Retain pipeline run history and validation outputs for submission.

## 7. Submission

Keep code and docs in GitHub; do not commit Raw response bodies or extracted data. Because Fabric GitHub integration is unavailable in the assessment tenant, use notebook import/upload from the repository ZIP. Preserve the notebook item names so pipeline references stay valid.
