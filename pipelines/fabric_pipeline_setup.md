# Fabric Data Pipeline Setup

## One-time workspace items

In workspace `ws_fhir_assessment`, ensure these items exist:
- Lakehouse: `lh_fhir_assignment`
- Notebook: `nb_01_fhir_ingestion` (import from `notebooks/nb_01_fhir_ingestion.ipynb` or copy its cells)
- Notebook: `nb_02_silver_scd2`
- Notebook: `nb_03_gold_analytics`
- Warehouse: `wh_fhir_assignment`

Attach `lh_fhir_assignment` as the default Lakehouse to each notebook. When importing notebooks, verify the first configuration code cell in the ingestion notebook is marked as the **parameter cell**. The parameter names and defaults are:
- `resource_type` = `Patient`
- `initial_lookback_days` = `3`
- `page_size` = `100`
- `overlap_minutes` = `5`
- `max_pages` = `1000`
- `request_format` = `json`

Do not change `resource_type` in the source code between pipeline runs; override it using the Notebook activity's Base parameters.

## Create the pipeline

Create a Fabric Data Pipeline named `pl_fhir_assessment`. Add Notebook activities connected by **On success** dependencies in this order:

| Activity | Notebook | Base parameters |
|---|---|---|
| `Ingest_Patient` | `nb_01_fhir_ingestion` | `resource_type = Patient`; other parameters use defaults or pipeline parameters |
| `Ingest_Encounter` | `nb_01_fhir_ingestion` | `resource_type = Encounter` |
| `Ingest_Observation` | `nb_01_fhir_ingestion` | `resource_type = Observation` |
| `Ingest_Condition` | `nb_01_fhir_ingestion` | `resource_type = Condition` |
| `Transform_Silver_SCD2` | `nb_02_silver_scd2` | none |
| `Build_Gold_Tables` | `nb_03_gold_analytics` | none |

Link them sequentially with success dependencies through `Build_Gold_Tables`. If using pipeline parameters for page size, lookback, overlap, and safety limit, create them at the pipeline level and pass them as Base parameters to all four ingestion activity instances. Resource names are fixed per activity to preserve the assignment-required sequence; the ingestion logic itself is reusable.

## Create Warehouse views over Gold

No Gold Copy Data activities are needed. The data remains in Lakehouse schema `gold`; the Warehouse provides SQL views over it.

## Create the SQL views

In `wh_fhir_assignment`, add the Lakehouse SQL analytics endpoint `lh_fhir_assignment` using the SQL editor's **+ Warehouses** action, then execute `warehouse/create_gold_views.sql`. This creates `dbo.vw_Patient`, `dbo.vw_Encounter`, `dbo.vw_Observation`, and `dbo.vw_Condition`. The view script is a one-time deployment step; no copy activity is required.

## Executing the 2–3-day requirement

1. Run the pipeline once. The first run uses a three-day source `_lastUpdated` lookback.
2. Run it again on the following day, and again on a third day if schedule permits. The saved watermark plus overlap will drive subsequent incremental queries.
3. Keep pipeline run details and query results from `fhir_ingestion_audit` showing separate successful run IDs/timestamps. The initial lookback alone is not evidence of separate daily runs.

Do not advance a watermark after a partial pagination run. If the safety page limit is hit, increase `max_pages` and rerun; the notebook fails rather than marking the incomplete fetch successful.

## Schedule (optional operational step)

Once manual execution succeeds, configure a daily schedule if permitted. For assessment evidence, make sure the required 2–3 days of actual run history are retained.

## Known platform UI variation

Fabric UI labels can vary. If import doesn't bind a notebook to the Lakehouse, attach `lh_fhir_assignment` manually. If the imported parameter tag is not recognized, select the configuration cell and mark it as the Notebook parameter cell in Fabric. Never commit Raw FHIR payloads to GitHub.
