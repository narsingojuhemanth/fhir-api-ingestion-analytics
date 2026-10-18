# Data Dictionary

## Raw files

| Artifact | Meaning |
|---|---|
| `page_NNNNN.json` | Original successful API response body; do not edit or reserialize it |
| `page_NNNNN.metadata.json` | Sidecar request, extraction, save, status, and raw-path metadata |

Each resource has its own date-bucketed directory.

## `fhir_ingestion_audit`

| Column | Meaning |
|---|---|
| `run_id` | Unique ingestion run identifier |
| `resource_type` | Patient, Encounter, Observation, or Condition |
| `page_number` | 1-based page/attempt number within the run |
| `api_call_timestamp` | UTC request-start timestamp |
| `extraction_timestamp` | UTC extraction timestamp |
| `saved_timestamp` | UTC time after the successful Raw response was written |
| `api_url_or_params` | Actual URL requested, including pagination URLs |
| `raw_file_path` | Lakehouse path for the response payload |
| `metadata_file_path` | Lakehouse path for its sidecar metadata |
| `http_status` | HTTP status; 0 means no response status was obtained |
| `records_received` | Number of entries in the returned Bundle |
| `page_status` | `RAW_SAVED` or failure marker |
| `run_status` | Overall run status as recorded in the audit row |
| `error_message` | Error details for failed attempts, when available |

## `fhir_ingestion_watermarks`

| Column | Meaning |
|---|---|
| `resource_type` | Resource to which the checkpoint belongs |
| `last_successful_source_updated_utc` | Maximum observed FHIR resource `meta.lastUpdated` from the completed run |
| `last_successful_run_id` | Run that wrote the watermark |
| `watermark_updated_at_utc` | Time the checkpoint was persisted |

## Bronze tables

Tables: `bronze.Patient`, `bronze.Encounter`, `bronze.Observation`, `bronze.Condition`.

| Column | Meaning |
|---|---|
| `resource_type`, `resource_id` | FHIR resource identity |
| `source_last_updated` | Source `meta.lastUpdated` string |
| `resource_json` | Canonicalized resource JSON string for downstream parsing; Raw file remains the original response |
| `content_hash` | SHA-256 of canonicalized resource JSON |
| `extraction_date` | UTC date associated with the extraction run |
| `extraction_timestamp` | UTC extraction timestamp |
| `api_url_or_params` | Actual response request URL |
| `raw_file_path` | Originating Raw Bundle response file |
| `ingestion_run_id` | Ingestion run identifier |
| `saved_timestamp` | Time after the Raw page was saved |

Bronze MERGE key: `resource_type + resource_id + content_hash`. The table retains unique observed content versions while preventing exact re-ingestion duplicates.

## Silver tables

Tables: `silver.Patient`, `silver.Encounter`, `silver.Observation`, `silver.Condition`.

Silver retains Bronze columns and adds:
- `valid_from`: effective timestamp for the observed version.
- `valid_to`: next observed version's effective timestamp, null for the latest version.
- `is_current`: true for the latest observed version of a resource.
- `scd2_rebuilt_timestamp`: UTC time the Silver history was rebuilt.

## Gold tables

Tables: `gold.Patient`, `gold.Encounter`, `gold.Observation`, `gold.Condition`.

Gold stores current-state analytical projections. See each output schema in `notebooks/nb_03_gold_analytics.ipynb`. Historical rows remain in Silver.

## Warehouse views

- `dbo.vw_Patient`
- `dbo.vw_Encounter`
- `dbo.vw_Observation`
- `dbo.vw_Condition`

Create them by running `warehouse/create_gold_views.sql` in `wh_fhir_assignment` after adding the Lakehouse SQL analytics endpoint to the Warehouse explorer. The views reference the Lakehouse Gold tables directly, without copying the Gold data.
