# Fabric Notebook Source

These Jupyter-format notebooks are intended to be imported into the Microsoft Fabric workspace `ws_fhir_assessment`.

## Files and execution order

1. `nb_00_setup_cleanup.ipynb` — manual, one-time cleanup only. It defaults to dry-run. To reset only this assessment's managed tables and Raw data, explicitly set `CONFIRM_RESET = "RESET_FHIR_ASSESSMENT"` and `DELETE_RAW_FILES = True`, attach `lh_fhir_assignment`, then run it once. Never add this notebook to the recurring pipeline.
2. `nb_01_fhir_ingestion.ipynb` — parameterized Raw/Bronze ingestion for one resource per pipeline activity. The first startup cell creates the `bronze`, `silver`, and `gold` schemas and only drops legacy prefixed duplicate tables when the corresponding schema-based replacement exists. It does not drop active layer tables, audit/watermark tables, or Raw files.
3. `nb_02_silver_scd2.ipynb` — Spark cleanup/deduplication and SCD Type 2 reconstruction for all four Bronze tables.
4. `nb_03_gold_analytics.ipynb` — current-state analytics Gold Delta tables for all four resources.

## Safe clean-start instructions

1. Make sure `lh_fhir_assignment` is attached as the default Lakehouse.
2. Import `nb_00_setup_cleanup.ipynb` and attach the Lakehouse.
3. To perform a full reset of this assessment's data, edit the parameter cell: set `CONFIRM_RESET = "RESET_FHIR_ASSESSMENT"` and `DELETE_RAW_FILES = True`. Run the notebook once and verify it reports reset completed. If you do not need to remove existing Raw files, set `DELETE_RAW_FILES = False`.
4. After reset, empty `CONFIRM_RESET` and save the cleanup notebook so it is safe if reopened. Do not include it in the pipeline.
5. Import or update the three production notebooks, keeping these item names:
   - `nb_01_fhir_ingestion`
   - `nb_02_silver_scd2`
   - `nb_03_gold_analytics`
6. Attach `lh_fhir_assignment` as the default Lakehouse for all three.
7. Keep the parameter cell in `nb_01_fhir_ingestion` marked as the notebook parameter cell. Default values are:
   - `resource_type = "Patient"`
   - `initial_lookback_days = 3`
   - `page_size = 100`
   - `overlap_minutes = 5`
   - `max_pages = 1000`
   - `request_format = "json"`
   - `cleanup_legacy_tables = True`
8. In the pipeline, set the resource type Base parameter for each ingestion activity to Patient, Encounter, Observation, or Condition. The reset notebook must not be linked to the pipeline.
9. Run the pipeline. It should execute Patient → Encounter → Observation → Condition → Silver → Gold.
10. Create the Warehouse views using `warehouse/create_gold_views.sql` after the Lakehouse Gold tables exist.

## Updating existing pipeline-linked notebook items

Fabric GitHub integration was unavailable in this assessment tenant, so new GitHub commits do not synchronize automatically. To preserve pipeline references, update the cell content in the existing Fabric notebook items in place. If you import new notebook items instead, edit each pipeline activity to select the newly imported item.

## Important runtime validation

The notebooks are source artifacts until successfully run in the target workspace. Verify the acceptance checklist and keep evidence of successful runs across 2–3 days. The full one-time reset is destructive and should be used only on the dedicated assessment Lakehouse.
