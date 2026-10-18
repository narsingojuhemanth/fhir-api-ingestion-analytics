# Fabric Data Pipeline Setup

## Workspace assets

In workspace `ws_fhir_assessment`, ensure these assets exist:
- Lakehouse: `lh_fhir_assignment` (schema-enabled)
- One-time reset notebook: `nb_00_setup_cleanup` (manual only; never added to the pipeline)
- Ingestion notebook: `nb_01_fhir_ingestion`
- Silver notebook: `nb_02_silver_scd2`
- Gold notebook: `nb_03_gold_analytics`
- Warehouse: `wh_fhir_assignment`

Attach `lh_fhir_assignment` as the default Lakehouse to all notebooks. The reset notebook is a manual utility and is not a pipeline activity.

## Clean-start preparation (manual, one time only)

If starting fresh in the dedicated assessment Lakehouse, import `notebooks/nb_00_setup_cleanup.ipynb`, attach `lh_fhir_assignment`, then set its parameters:
- `CONFIRM_RESET = "RESET_FHIR_ASSESSMENT"`
- `DELETE_RAW_FILES = True` to remove only `Files/raw/fhir` from this assessment Lakehouse (use `False` to preserve Raw files)

Run that notebook exactly once and verify the reset completion message. Then return `CONFIRM_RESET` to an empty string and save the notebook. Do not add the reset notebook to the pipeline: each pipeline run must preserve watermarks, incremental state, and SCD Type 2 history.

The ingestion notebook also has a safe startup cell. It creates the `bronze`, `silver`, and `gold` schemas if absent. It removes old prefixed duplicate tables only when the corresponding schema-based replacement exists. It does not drop the current medallion tables, control tables, or Raw payloads.

## Ingestion notebook parameters

The configuration cell in `nb_01_fhir_ingestion` must be tagged as the notebook parameter cell. Defaults:
- `resource_type = "Patient"`
- `initial_lookback_days = 3`
- `page_size = 100`
- `overlap_minutes = 5`
- `max_pages = 1000`
- `request_format = "json"`
- `cleanup_legacy_tables = True` (safe legacy cleanup; it drops only old prefixed duplicates when schema-based replacements exist)
- `cleanup_legacy_tables = True`

The pipeline should override `resource_type` in each ingestion activity. The other parameters may use their defaults. If adding pipeline-level parameters, pass all of them explicitly to every ingestion activity.

## Create the orchestration pipeline

Create or update Fabric Data Pipeline `pl_fhir_assessment`. Add Notebook activities linked with **On success** dependencies in this exact order:

| Sequence | Activity | Notebook | Base parameter override |
|---:|---|---|---|
| 1 | `Ingest_Patient` | `nb_01_fhir_ingestion` | `resource_type = Patient` |
| 2 | `Ingest_Encounter` | `nb_01_fhir_ingestion` | `resource_type = Encounter` |
| 3 | `Ingest_Observation` | `nb_01_fhir_ingestion` | `resource_type = Observation` |
| 4 | `Ingest_Condition` | `nb_01_fhir_ingestion` | `resource_type = Condition` |
| 5 | `Transform_Silver_SCD2` | `nb_02_silver_scd2` | none |
| 6 | `Build_Gold_Tables` | `nb_03_gold_analytics` | none |

Link each activity to the next using the green **On success** dependency. Keep the first four resource activities in the prescribed order. Do not add `nb_00_setup_cleanup` to this pipeline.

## Table layout

The ingestion notebooks use these schema-qualified Lakehouse tables:
- Bronze: `bronze.Patient`, `bronze.Encounter`, `bronze.Observation`, `bronze.Condition`
- Silver: `silver.Patient`, `silver.Encounter`, `silver.Observation`, `silver.Condition`
- Gold: `gold.Patient`, `gold.Encounter`, `gold.Observation`, `gold.Condition`
- Control: `dbo.fhir_ingestion_audit`, `dbo.fhir_ingestion_watermarks`

No Copy Data activities are required for Gold. The Gold tables remain in the Lakehouse; the Warehouse exposes direct SQL views over them. This avoids a duplicate Gold copy and is an implementation choice, not an explicit separate-copy requirement in the assignment brief.

## Create Warehouse views

After the Gold tables exist:
1. Open `wh_fhir_assignment`.
2. In Explorer, select **+ Warehouses** and add the SQL analytics endpoint for `lh_fhir_assignment`.
3. Open a new SQL query and run each view definition in `warehouse/create_gold_views.sql`. The statements are separated by `GO`; Fabric's SQL query editor treats `GO` as a new batch.
4. Validate each view with a small query, for example `SELECT TOP (20) * FROM dbo.vw_Patient;`.

The views are `dbo.vw_Patient`, `dbo.vw_Encounter`, `dbo.vw_Observation`, and `dbo.vw_Condition`. If these views already exist and you intentionally want to recreate them, first execute `warehouse/drop_gold_views.sql`; it removes only the views, not Lakehouse data.

## Required 2–3-day evidence

1. Run the pipeline once after the clean start.
2. Run again on the following day and again on a third day if feasible.
3. Verify that separate successful run IDs/timestamps exist for all resource types in `dbo.fhir_ingestion_audit`.
4. Verify the watermarks in `dbo.fhir_ingestion_watermarks`.
5. If an updated resource is observed, verify Bronze stores a changed content hash and Silver retains both versions with one current version and a closed prior interval.

A single initial three-day lookback is not evidence of successful ingestion on separate days. Do not advance a watermark after a failed or incomplete paginated run.

## Source control and final submission

Use the GitHub repository for source code and documentation; do not commit Raw payloads or credentials. Since Fabric GitHub integration was blocked in the assessment tenant, update existing notebook items in place to preserve pipeline references. If importing notebooks as new workspace items, update each pipeline activity to point to the new item.

Follow `tests/acceptance_checklist.md` before delivery and include the project code, notebooks, pipeline recreation documentation, table lineage, and a ZIP backup.
