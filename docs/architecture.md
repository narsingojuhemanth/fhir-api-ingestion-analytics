# Architecture

## Source API

Public HAPI FHIR R4 base URL: https://hapi.fhir.org/baseR4

The solution ingests these resource types: Patient, Encounter, Observation, and Condition. Search responses are FHIR searchset Bundles. Pagination follows the Bundle link with relation `next`; the client does not construct page offsets.

## Layers

### Raw

Store each successful HTTP response body as received under:

```text
Files/raw/fhir/
  resource=Patient/
    extraction_date=YYYY-MM-DD/
      run_id=YYYYMMDDTHHMMSSffffffZ/
        page_00001.json
        page_00001.metadata.json
```

Repeat for Encounter, Observation, and Condition. The original response is not parsed and reserialized for Raw storage; page metadata is kept in a separate sidecar file.

### Bronze

One Delta table per resource, in the Bronze schema:
- `bronze.Patient`
- `bronze.Encounter`
- `bronze.Observation`
- `bronze.Condition`

Bronze stores resource identity, canonical resource JSON, source update timestamp, content hash, Raw path, extraction timestamp, actual API URL/parameters, ingestion run ID, and save timestamp. A Delta MERGE keyed by resource type, resource ID, and content hash retains each observed content version without duplicating identical payload versions from overlapping incremental scans.

### Silver

One Delta table per resource:
- `silver.Patient`
- `silver.Encounter`
- `silver.Observation`
- `silver.Condition`

Spark removes malformed records and exact duplicate payload versions. Different hashes for the same resource are retained as separate SCD Type 2 versions, with `valid_from`, `valid_to`, and `is_current`. Source `meta.lastUpdated` is preferred for version time; extraction/save time is the fallback.

### Gold

One current-state analytical Delta table per resource:
- `gold.Patient`
- `gold.Encounter`
- `gold.Observation`
- `gold.Condition`

Gold extracts commonly used fields from the JSON resource, including Patient demographics, Encounter status/period/subject, Observation code/value/effective time, and Condition status/code/subject.

### Warehouse views

Warehouse `wh_fhir_assignment` exposes four SQL views:
- `dbo.vw_Patient`
- `dbo.vw_Encounter`
- `dbo.vw_Observation`
- `dbo.vw_Condition`

The views reference Lakehouse Gold tables through same-workspace three-part naming. This meets the Warehouse-view requirement without maintaining a duplicate copy of the Gold data. Microsoft documents this cross-database pattern in its [Fabric Warehouse query guide](https://learn.microsoft.com/en-us/fabric/data-warehouse/query-warehouse).

## Metadata and audit

Control tables stay in the default Lakehouse schema:
- `dbo.fhir_ingestion_audit`: one row per page or failed page attempt.
- `dbo.fhir_ingestion_watermarks`: latest successfully observed source timestamp by resource type.

Required metadata:
- `extraction_timestamp`: time of the API page extraction.
- `api_url_or_params`: the actual URL requested, including the server-provided paging URL.
- `api_call_timestamp`: API-call start time.
- `saved_timestamp`: time after the Raw response was saved.
- `source_last_updated`: the resource's FHIR `meta.lastUpdated`.
- `content_hash`: SHA-256 hash of canonicalized resource JSON.
- `ingestion_run_id`: run identifier joining Raw, audit, and Bronze records.

## Incremental behavior

On a resource's first run, use the configurable lookback (default three days) through `_lastUpdated=ge...`. On later runs, use the saved source watermark minus a configurable overlap (default five minutes). If a completed scan returns no resources, advance conservatively to the scan start minus the configured overlap; the next run subtracts the overlap again. If resources are returned but lack source timestamps, retain the existing watermark. A failed request, failed load, or pagination safety-limit failure must not be treated as a successful run.

The assessment requires successful ingestion across 2–3 separate days. Run the pipeline on separate days and keep audit/run evidence; the initial lookback alone is not sufficient.

## Orchestration

The Fabric Data Pipeline runs these activities sequentially with On success dependencies:

1. Ingest Patient
2. Ingest Encounter
3. Ingest Observation
4. Ingest Condition
5. Transform Silver SCD Type 2
6. Build Gold tables

Warehouse views are created once from the supplied SQL script and then reflect refreshed Gold tables automatically.

## Transformation constraint

Spark notebooks parse JSON into tables. Dataflows Gen2 is not used for JSON-to-table conversion.
