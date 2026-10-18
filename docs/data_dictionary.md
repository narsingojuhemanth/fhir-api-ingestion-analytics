# Data Dictionary

## Raw response files

| Artifact | Description |
|---|---|
| `page_NNNNN.json` | Original successful FHIR Bundle response body |
| `page_NNNNN.metadata.json` | Separate request, extraction, save, HTTP status, count, and Raw path metadata |

Raw directory structure is bucketed by resource type, extraction date, and run ID.

## Control tables

### `dbo.fhir_ingestion_audit`

| Column | Meaning |
|---|---|
| `run_id` | Unique ingestion run |
| `resource_type` | Patient, Encounter, Observation, or Condition |
| `page_number` | Page/attempt sequence within the run |
| `api_call_timestamp` | UTC time the API request began |
| `extraction_timestamp` | UTC extraction timestamp |
| `saved_timestamp` | UTC time after the Raw response was saved; null for failed attempt |
| `api_url_or_params` | Actual requested URL, including paging URLs |
| `raw_file_path` | Saved response path |
| `metadata_file_path` | Sidecar file path |
| `http_status` | HTTP status or 0 when no response status was available |
| `records_received` | Number of Bundle entries returned |
| `page_status` | `RAW_SAVED` or `RUN_FAILURE` |
| `run_status` | `SUCCESS`, `IN_PROGRESS`, or `FAILED` |
| `error_message` | Failure detail when available |

### `dbo.fhir_ingestion_watermarks`

| Column | Meaning |
|---|---|
| `resource_type` | Resource-specific checkpoint |
| `last_successful_source_updated_utc` | Maximum source `meta.lastUpdated` timestamp observed in a completed run; if the completed scan returns no resources, the watermark advances conservatively to run start minus overlap |
| `last_successful_run_id` | Run that saved the checkpoint |
| `watermark_updated_at_utc` | UTC timestamp when the watermark was written |

## Bronze tables

Tables: `bronze.Patient`, `bronze.Encounter`, `bronze.Observation`, `bronze.Condition`.

| Column | Meaning |
|---|---|
| `resource_type`, `resource_id` | FHIR resource identity |
| `source_last_updated` | FHIR `meta.lastUpdated` |
| `resource_json` | Canonical JSON string for downstream parsing |
| `content_hash` | SHA-256 hash of canonicalized resource JSON |
| `extraction_date` | UTC date associated with the extraction |
| `extraction_timestamp` | Time the resource was extracted |
| `api_url_or_params` | Actual API request URL |
| `raw_file_path` | Original Bundle response file containing the resource |
| `ingestion_run_id` | Ingestion run identifier |
| `saved_timestamp` | Time after Raw data was saved |

Bronze MERGE key: resource type + resource ID + content hash.

## Silver tables

Tables: `silver.Patient`, `silver.Encounter`, `silver.Observation`, `silver.Condition`.

Silver retains Bronze columns and adds:
- `valid_from`: effective start time of the observed content version.
- `valid_to`: start time of the next observed version; null for the current version.
- `is_current`: true only for the latest observed version of a resource.

## Gold tables

Tables: `gold.Patient`, `gold.Encounter`, `gold.Observation`, `gold.Condition`.

Gold contains current-state analytic projections with stable resource IDs, commonly used FHIR fields, and the required metadata columns extraction_timestamp and api_url_or_params, plus source_last_updated, content_hash, valid_from, valid_to, is_current, ingestion_run_id, and saved_timestamp. Historical versions remain in Silver.

## Warehouse views

- `dbo.vw_Patient`
- `dbo.vw_Encounter`
- `dbo.vw_Observation`
- `dbo.vw_Condition`

The view definitions are in `warehouse/create_gold_views.sql`.
