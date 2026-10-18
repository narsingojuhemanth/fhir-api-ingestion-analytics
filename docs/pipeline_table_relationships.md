# Pipeline and Table Relationships

## Pipeline activity order

Fabric Data Pipeline `pl_fhir_assessment` runs these six Notebook activities sequentially using **On success** dependencies:

| Order | Activity | Notebook | Parameter |
|---:|---|---|---|
| 1 | `Ingest_Patient` | `nb_01_fhir_ingestion` | `resource_type = Patient` |
| 2 | `Ingest_Encounter` | `nb_01_fhir_ingestion` | `resource_type = Encounter` |
| 3 | `Ingest_Observation` | `nb_01_fhir_ingestion` | `resource_type = Observation` |
| 4 | `Ingest_Condition` | `nb_01_fhir_ingestion` | `resource_type = Condition` |
| 5 | `Transform_Silver_SCD2` | `nb_02_silver_scd2` | none |
| 6 | `Build_Gold_Tables` | `nb_03_gold_analytics` | none |

Do not change the specified order of the four resource activities. All notebooks use `lh_fhir_assignment` as the default Lakehouse.

## Table lineage

```text
HAPI FHIR R4
  Patient     → Raw resource=Patient     → bronze.Patient     → silver.Patient     → gold.Patient     → dbo.vw_Patient
  Encounter   → Raw resource=Encounter   → bronze.Encounter   → silver.Encounter   → gold.Encounter   → dbo.vw_Encounter
  Observation → Raw resource=Observation → bronze.Observation → silver.Observation → gold.Observation → dbo.vw_Observation
  Condition   → Raw resource=Condition    → bronze.Condition    → silver.Condition    → gold.Condition    → dbo.vw_Condition

Every ingestion run also writes:
  dbo.fhir_ingestion_audit
  dbo.fhir_ingestion_watermarks
```

## Loading and transformations

- Ingestion saves the original Bundle body and a metadata sidecar to Raw, then merges the resources into Bronze.
- Silver cleans and deduplicates Bronze content versions and derives SCD Type 2 validity intervals.
- Gold selects the current Silver version and extracts analytic fields.
- The Warehouse SQL views reference Lakehouse Gold tables directly. No Gold Copy Data activities are required; this avoids duplicate storage and the views reflect refreshed Gold tables.

## Daily incremental runs

Run the pipeline on separate days over the required 2–3-day observation period. Verify distinct run IDs in the audit table and inspect per-resource watermarks. If changed resource content is returned by the API, it should appear as a different Bronze content hash and as a retained Silver version.
