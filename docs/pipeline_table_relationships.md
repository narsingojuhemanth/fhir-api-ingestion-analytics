# Pipeline and Table Relationships

## Required orchestration order

The first four notebook activities must execute sequentially in this exact order:

1. `Ingest_Patient`
2. `Ingest_Encounter`
3. `Ingest_Observation`
4. `Ingest_Condition`

Configure each Notebook activity to run only after the preceding activity **succeeds**. This preserves the assignment's required order of Patient → Encounter → Observation → Condition.

After those four activities:
5. `Transform_Silver_SCD2` runs `nb_02_silver_scd2`.
6. `Build_Gold_Tables` runs `nb_03_gold_analytics`.
7. Four Copy Data activities load the Gold tables to the matching Warehouse tables. These copies can run in parallel after Gold finishes.
8. Run `warehouse/create_gold_views.sql` using a Warehouse Script activity if available in the tenant; otherwise execute it manually in the Warehouse SQL query editor after the first load.

## Lineage

```text
HAPI FHIR R4
  ├─ Patient    → Raw resource=Patient    → bronze_fhir_patient    → silver_fhir_patient    → gold_fhir_patient    → dbo.vw_gold_patient
  ├─ Encounter  → Raw resource=Encounter  → bronze_fhir_encounter  → silver_fhir_encounter  → gold_fhir_encounter  → dbo.vw_gold_encounter
  ├─ Observation→ Raw resource=Observation→ bronze_fhir_observation→ silver_fhir_observation→ gold_fhir_observation→ dbo.vw_gold_observation
  └─ Condition  → Raw resource=Condition  → bronze_fhir_condition  → silver_fhir_condition  → gold_fhir_condition  → dbo.vw_gold_condition

All resource ingestion activities also write:
- fhir_ingestion_audit
- fhir_ingestion_watermarks
```

## Dependencies

- Each ingestion activity requires the default Lakehouse `lh_fhir_assignment`.
- Silver requires all four Bronze tables; run it after all resource ingestion activities.
- Gold requires all four Silver tables; run it after Silver succeeds.
- Warehouse views require the corresponding `dbo.gold_fhir_*` tables to exist in `wh_fhir_assignment`.
- The notebooks are idempotent for exact Bronze content versions. Raw page files are intentionally immutable and receive a new run folder each run.
