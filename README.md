# FHIR API Ingestion and Analytics

A Microsoft Fabric project that ingests FHIR R4 resources from the public HAPI FHIR API, keeps the raw API responses, tracks resource versions, and prepares reporting tables for Power BI.

## What is included

- Ingestion of **Patient**, **Encounter**, **Observation**, and **Condition** resources with server-provided pagination.
- Raw API response bodies saved unchanged in Lakehouse Files, with request and save metadata stored separately.
- Bronze Delta tables for source resource content and metadata.
- Silver tables with cleansing, deduplication, and SCD Type 2 history.
- Gold tables with fields selected for analysis.
- A Fabric pipeline that runs the four resource ingestions in order, followed by Silver and Gold.
- Four Warehouse views, a semantic-model relationship guide, validation SQL, and setup documentation.

## Architecture

```text
HAPI FHIR R4 API
      |
      v
Raw response files + metadata sidecars
      |
      v
Bronze Delta tables
      |
      v
Silver Delta tables (SCD Type 2)
      |
      v
Gold analytical tables
      |
      v
Warehouse views -> Power BI semantic model -> report
```

| Layer | Tables / location | Purpose |
|---|---|---|
| Raw | Lakehouse Files: `raw/fhir/resource=.../extraction_date=.../run_id=...` | Preserve original paginated API responses |
| Bronze | `bronze.Patient`, `bronze.Encounter`, `bronze.Observation`, `bronze.Condition` | Store resource JSON, hashes, source timestamps, and ingestion metadata |
| Silver | `silver.Patient`, `silver.Encounter`, `silver.Observation`, `silver.Condition` | Clean and deduplicate content; retain version history |
| Gold | `gold.Patient`, `gold.Encounter`, `gold.Observation`, `gold.Condition` | Expose current resource fields for analysis |
| Warehouse | `dbo.vw_Patient`, `dbo.vw_Encounter`, `dbo.vw_Observation`, `dbo.vw_Condition` | Provide SQL views over Gold for the semantic model |

## Power BI model

The semantic model uses the four Warehouse views. `vw_Patient[patient_id]` is the one-side key, related one-to-many to `patient_id` in `vw_Encounter`, `vw_Observation`, and `vw_Condition`. Use single-direction filtering from Patient to each resource table. The field mapping and report evidence are documented under [Power BI model](docs/power_bi_model.md).

## Fabric run order

The pipeline is configured with success dependencies in this order:

1. `Ingest_Patient`
2. `Ingest_Encounter`
3. `Ingest_Observation`
4. `Ingest_Condition`
5. `Transform_Silver_SCD2`
6. `Build_Gold_Tables`

Run `nb_04_validation` separately after a successful pipeline run. The current validation run returned **OVERALL: PASS**. The Warehouse views and Power BI report have also been created in the Fabric workspace.

## Repository layout

```text
notebooks/    Four Fabric notebooks: ingestion, Silver, Gold, validation
pipelines/    Pipeline activities, parameters, and execution order
warehouse/    SQL script for the four Warehouse views
docs/         Architecture, data dictionary, lineage, requirements, Power BI model
tests/        Validation queries, notebook syntax check, acceptance checklist
evidence/     Fabric and Power BI screenshots for the submission
```

## Import and run

1. Create a Fabric workspace, a schema-enabled Lakehouse named `lh_fhir_assignment`, and a Warehouse named `wh_fhir_assignment`.
2. Import the four `.ipynb` files from `notebooks/` and attach `lh_fhir_assignment` as the default Lakehouse.
3. Keep the first cell in `nb_01_fhir_ingestion` marked as the notebook parameter cell.
4. Create `pl_fhir_assessment` following [the pipeline setup guide](pipelines/fabric_pipeline_setup.md).
5. Run the pipeline and then run `nb_04_validation`.
6. In `wh_fhir_assignment`, add the Lakehouse SQL analytics endpoint through **+ Warehouses**, then execute [`warehouse/create_gold_views.sql`](warehouse/create_gold_views.sql).
7. Build the semantic model from the four views and follow [the model relationship guide](docs/power_bi_model.md).

## Validation and evidence

The validation notebook checks required metadata, duplicate content versions, current Silver versions, SCD Type 2 intervals, Gold IDs, Raw sidecars, audit records, and watermarks. Supporting screenshots belong in [`evidence/`](evidence/README.md).

The assignment asks for incremental ingestion across 2–3 separate days. The initial three-day lookback does not by itself demonstrate separate-day runs; retain actual run-history evidence from the dates you ran the pipeline. Repeated runs on the same date should not be presented as separate-day evidence.

## Source and data handling

The source is the public [HAPI FHIR R4 API](https://hapi.fhir.org/baseR4). Raw responses and extracted datasets are runtime data: do not commit them, credentials, or tokens to this repository.
