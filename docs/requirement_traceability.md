# Assignment requirement mapping

| Assignment requirement | Implementation | Evidence |
|---|---|---|
| Use Microsoft Fabric or Databricks with source control | Fabric notebooks, pipeline, SQL, and documentation are in this repository | Repository and workspace |
| Use public HAPI FHIR R4 | Ingestion calls the HAPI R4 base URL | Audit rows for all four resources |
| Ingest Patient, Encounter, Observation, and Condition | One parameterized notebook is called once per resource | Pipeline configuration and run history |
| Incremental ingestion with pagination | Watermarks, overlap, and server-provided `next` URLs | Audit log, Raw folders, and actual run history |
| Preserve original JSON responses | Successful Bundle response bodies are saved unchanged; metadata is in separate sidecars | Raw files by resource, date, and run |
| Store Bronze data in Delta/Parquet | Four schema-based Bronze Delta tables | Bronze table inspection and counts |
| Record extraction and request details | `extraction_timestamp`, `api_url_or_params`, API-call and save timestamps | Bronze metadata, audit rows, and sidecars |
| Retain changes with SCD Type 2 | Bronze content hashes and Silver version intervals | Silver rows with `valid_from`, `valid_to`, `is_current` |
| Clean and deduplicate data | Spark transformations build Silver from Bronze | Validation notebook and SQL checks |
| Build Gold reporting tables | Four analytical Gold Delta tables | Gold table inspection and counts |
| Publish Warehouse views | Four views reference current Gold rows | Execute the SQL in `warehouse/create_gold_views.sql` |
| Run activities in the requested order | Patient → Encounter → Observation → Condition → Silver → Gold | Pipeline dependency view and successful run |
| Keep code modular and reusable | A parameterized ingestion notebook is reused for all resources | Pipeline parameter settings |
| Document pipeline and table relationships | Architecture, data dictionary, lineage, pipeline and Power BI model guides | Files under `docs/` and `pipelines/` |
| Submit code and setup material | Notebooks, SQL, validation, and setup documentation | This repository |

## Power BI report

The Power BI semantic model uses the four Warehouse views. The Patient key relates one-to-many to the patient key in Encounter, Observation, and Condition. The report is an additional deliverable; see [the model guide](power_bi_model.md) and screenshots in `evidence/` when available.

## Optional assignment extensions

- XML ingestion.
- One-page Power BI report.

The Power BI report has been created in the Fabric workspace. Only claim runtime behavior that is supported by actual notebook, pipeline, or report evidence. The required 2–3 separate-day ingestion evidence should use the actual run dates; multiple runs on one date are not separate-day evidence.
