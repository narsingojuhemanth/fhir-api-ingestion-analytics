# FHIR API Ingestion & Analytics

Microsoft Fabric assessment project using the public HAPI FHIR R4 API.

## Project assets

| Item | Purpose |
|---|---|
| Workspace | `ws_fhir_assessment` |
| Lakehouse | `lh_fhir_assignment` |
| Warehouse | `wh_fhir_assignment` |
| Pipeline | `pl_fhir_assessment` |
| Ingestion notebook | `nb_01_fhir_ingestion` |
| Silver notebook | `nb_02_silver_scd2` |
| Gold notebook | `nb_03_gold_analytics` |
| Validation notebook | `nb_04_validation` |
| One-time reset notebook | `nb_00_setup_cleanup` |

## Runtime evidence completed in the current workspace

- [x] Microsoft Fabric and Spark environment verified.
- [x] HAPI FHIR R4 connectivity checked for Patient, Encounter, Observation, and Condition.
- [x] Pagination tested by following the server-provided `next` link.
- [x] First-page `_lastUpdated=ge...` filtering tested on all four resource endpoints.
- [x] Initial ingestion succeeded for all four resources with 121 Raw response pages and 11,778 resource entries observed: Patient 711, Encounter 4,409, Observation 4,707, Condition 1,951.
- [x] Bronze metadata/audit/watermark validation passed for all four resources.
- [x] Silver notebook executed and current-row uniqueness / validity-interval checks passed for the first load.
- [x] Gold notebook executed and key uniqueness / field-population checks passed for the first load.
- [x] The 12 schema-based Bronze/Silver/Gold copies were exactly compared with original prefixed tables; comparison passed.
- [x] Warehouse and six-core-stage pipeline were created in the workspace; the updated runbook adds a final validation activity as a seventh stage.
- [x] Schema-based notebook source, reset utility, validation notebook, view SQL, pipeline guide, data dictionary, and requirement traceability are committed here.

**Deployment qualification:** The successful first run occurred before the updated schema-based notebook source and reset/startup cells were imported into the existing Fabric notebook items. The schema-based table copies were validated, but the updated clean-start package must still be imported and executed in Fabric. Do not treat a committed notebook as proof that its updated version has run successfully.

## Clean-start quick steps

1. Download this repository ZIP using GitHub's **Code → Download ZIP**.
2. In `ws_fhir_assessment`, import `notebooks/nb_00_setup_cleanup.ipynb` and attach `lh_fhir_assignment`.
3. If you want a full clean reset of this dedicated assessment Lakehouse, set `CONFIRM_RESET = "RESET_FHIR_ASSESSMENT"` and `DELETE_RAW_FILES = True`, run the reset notebook exactly once, and confirm it reports reset completed. Its default configuration is dry-run and changes nothing.
4. Empty `CONFIRM_RESET` and save the reset notebook. **Never add the reset notebook to the pipeline.**
5. Update/import the notebook sources `nb_01_fhir_ingestion`, `nb_02_silver_scd2`, `nb_03_gold_analytics`, and `nb_04_validation`; attach `lh_fhir_assignment` as each notebook's default Lakehouse. Preserve notebook item names or update the pipeline activity references if you import new items.
6. In the ingestion notebook, verify its first configuration cell is marked as the Notebook parameter cell.
7. Run `pl_fhir_assessment`. Activities must run in order: Patient → Encounter → Observation → Condition → Silver SCD Type 2 → Gold tables → End-to-end validation. Set the final `nb_04_validation` activity's `RAISE_ON_FAILURE = True`.
8. Run `nb_04_validation` and inspect the full result.
9. In `wh_fhir_assignment`, add the `lh_fhir_assignment` SQL analytics endpoint via **+ Warehouses** and execute each view definition in `warehouse/create_gold_views.sql`. The views reference Lakehouse Gold tables directly; no duplicate Gold Copy Data activities are needed. If views already exist and you are intentionally recreating them, run `warehouse/drop_gold_views.sql` first.
10. Re-run the pipeline on separate days for the required 2–3-day evidence and validate SCD Type 2 behavior when an updated resource is observed. Keep successful audit/run evidence.

See `notebooks/README.md` and `pipelines/fabric_pipeline_setup.md` for the complete instructions.

## Architecture

```text
HAPI FHIR R4 API
  Patient → Encounter → Observation → Condition
                   |
                   v
Raw: original response bodies + request metadata sidecars
                   |
                   v
bronze schema: Patient / Encounter / Observation / Condition
                   |
                   v
silver schema: cleaned content versions + SCD Type 2 validity intervals
                   |
                   v
gold schema: analytics-ready current-state tables
                   |
                   v
wh_fhir_assignment: dbo.vw_Patient / vw_Encounter / vw_Observation / vw_Condition
```

Gold stays in the Lakehouse. Warehouse views read the Gold tables by same-workspace three-part naming. Audit and watermark tables use the `dbo` schema.

## Repository structure

- `notebooks/` — importable Jupyter notebooks for reset, ingestion, Silver, Gold, and validation.
- `warehouse/` — SQL statements for final Warehouse views.
- `docs/` — architecture, data dictionary, requirement traceability, and pipeline/table lineage.
- `pipelines/` — Fabric Data Pipeline setup runbook.
- `tests/` — validation queries and acceptance checklist.
- `src/` — optional location for additional reusable helpers.

## Assignment coverage

The implementation covers JSON ingestion from the public HAPI FHIR R4 API, pagination, date/resource-bucketed Raw response storage, Bronze Delta tables, required extraction/request metadata, API-call and save timestamps, hash-based change detection, Silver cleaning/deduplication, SCD Type 2 versioning, Gold tables and final Warehouse views, reusable parameterized code, ordered orchestration, and project documentation/submission instructions.

The assignment explicitly calls for separate successful incremental runs over 2–3 days. A single initial three-day lookback does not satisfy that proof. XML ingestion and a one-page Power BI report are optional extensions, deferred until all mandatory checks pass.

## Data handling

Do not commit credentials, tokens, raw FHIR payloads, or extracted datasets to this public repository. The Raw payloads and Delta tables belong in the Fabric Lakehouse; code and documentation belong in Git.
