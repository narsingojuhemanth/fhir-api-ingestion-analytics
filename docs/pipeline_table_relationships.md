# Pipeline and Table Relationships

## Required orchestration order

The first four notebook activities must execute sequentially in this exact order:

1. `Ingest_Patient`
2. `Ingest_Encounter`
3. `Ingest_Observation`
4. `Ingest_Condition`

Each Notebook activity calls `nb_01_fhir_ingestion` and overrides the `resource_type` parameter. Configure each activity to run only after the preceding activity **succeeds**.

After the four ingestion activities:
5. `Transform_Silver_SCD2` runs `nb_02_silver_scd2`.
6. `Build_Gold_Tables` runs `nb_03_gold_analytics`.
7. `Validate_End_To_End` runs `nb_04_validation` with `RAISE_ON_FAILURE = True` so quality failures fail the pipeline.

The final validation activity is recommended after Gold to check Raw/sidecar presence, Bronze metadata, Silver SCD2 integrity, Gold keys, and audit/watermark tables. The Warehouse views are created once in `wh_fhir_assignment` using `warehouse/create_gold_views.sql`. They reference Lakehouse Gold tables via three-part names; no scheduled Gold-to-Warehouse table copy is required.

## Lineage

```text
HAPI FHIR R4
  ├─ Patient     → Raw resource=Patient     → bronze.Patient     → silver.Patient     → gold.Patient     → dbo.vw_Patient
  ├─ Encounter   → Raw resource=Encounter   → bronze.Encounter   → silver.Encounter   → gold.Encounter   → dbo.vw_Encounter
  ├─ Observation → Raw resource=Observation → bronze.Observation → silver.Observation → gold.Observation → dbo.vw_Observation
  └─ Condition   → Raw resource=Condition    → bronze.Condition   → silver.Condition   → gold.Condition   → dbo.vw_Condition

All resource ingestion activities also write:
- dbo.fhir_ingestion_audit
- dbo.fhir_ingestion_watermarks
```

## Dependencies

- Each notebook requires `lh_fhir_assignment` attached as its default Lakehouse.
- Bronze tables are `bronze.Patient`, `bronze.Encounter`, `bronze.Observation`, and `bronze.Condition`.
- Silver requires all four Bronze tables; run it only after all resource ingestion activities succeed.
- Gold requires all four Silver tables; run it only after Silver succeeds.
- End-to-end validation requires Raw, Bronze, Silver, Gold, audit, and watermark outputs; run it only after Gold succeeds.
- Warehouse views require `wh_fhir_assignment` and the Lakehouse SQL analytics endpoint added in its object explorer.

## Warehouse view setup

In the Warehouse SQL query editor, add `lh_fhir_assignment` via **+ Warehouses**, then execute `warehouse/create_gold_views.sql`. The views use same-workspace three-part naming and read Lakehouse Gold tables directly, avoiding copied data.