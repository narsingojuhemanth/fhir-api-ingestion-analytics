# Architecture and Design

## Source

Public HAPI FHIR R4 base URL: https://hapi.fhir.org/baseR4

Required resources: Patient, Encounter, Observation, Condition.

The API returns searchset Bundles. A Bundle can contain multiple resource entries and server-managed pagination links. The ingestion notebook follows the Bundle `link` entry whose relation is `next`; it does not synthesize page offsets.

## Data flow

1. **Raw** — the successful HTTP response body is written to Lakehouse Files as response bytes, without parsing and reserializing the body. A separate sidecar JSON records request and save metadata.
2. **Bronze** — one Delta table per resource stores each distinct observed resource content version, a canonical JSON representation, SHA-256 content hash, originating Raw response path, extraction metadata, and run ID.
3. **Silver** — Spark filters malformed rows, deduplicates identical content versions, and builds SCD Type 2 validity intervals from source `meta.lastUpdated` when available.
4. **Gold** — Spark parses common FHIR fields into analytics-friendly current-state Delta tables.
5. **Warehouse** — `wh_fhir_assignment` exposes SQL views over Lakehouse Gold tables using same-workspace three-part naming. Gold data stays in the Lakehouse; it is not copied into a second set of Warehouse tables.

## Raw folder structure

```text
Files/
  raw/
    fhir/
      resource=Patient/
        extraction_date=YYYY-MM-DD/
          run_id=YYYYMMDDTHHMMSSffffffZ/
            page_00001.json
            page_00001.metadata.json
```

The same structure applies to Encounter, Observation, and Condition. Raw payloads and sidecar metadata are stored together but in separate files. Do not commit payload data to GitHub.

## Schemas and tables

- Bronze: `bronze.Patient`, `bronze.Encounter`, `bronze.Observation`, `bronze.Condition`
- Silver: `silver.Patient`, `silver.Encounter`, `silver.Observation`, `silver.Condition`
- Gold: `gold.Patient`, `gold.Encounter`, `gold.Observation`, `gold.Condition`
- Control: `dbo.fhir_ingestion_audit`, `dbo.fhir_ingestion_watermarks`

## Metadata and audit

- `extraction_timestamp`: time the page request/extraction started in UTC.
- `api_url_or_params`: actual URL used for that page, including the server-generated next URL when applicable.
- `api_call_timestamp`: request-start timestamp stored in the page audit table.
- `saved_timestamp`: timestamp after the Raw response body was written.
- `source_last_updated`: source FHIR resource `meta.lastUpdated`, used for incremental change detection.
- `content_hash`: SHA-256 hash of canonicalized resource JSON.
- `ingestion_run_id`: unique run ID tying page files and resource records together.

Audit table: `dbo.fhir_ingestion_audit`.
Watermark table: `dbo.fhir_ingestion_watermarks`, one latest checkpoint per resource type.

## Incremental strategy

The first run queries a configurable lookback (default 3 days) with FHIR `_lastUpdated=ge...`. After a complete successful scan with valid source timestamps, the notebook persists the maximum observed `meta.lastUpdated` as that resource's watermark. Subsequent scans start from that watermark minus the configured overlap (default 5 minutes). A complete successful scan returning no resources can advance the checkpoint to the run start; a scan returning resources without any source timestamps does not advance it.

Bronze MERGE keys on resource type, resource ID, and content hash, so overlap does not create duplicate content versions. A pagination safety limit or fetch/parse/load failure must not be treated as a successful run or advance the watermark.

**Assessment evidence:** retain successful run IDs and timestamps from separate days across 2–3 days. A single initial three-day lookback does not prove separate daily ingestion runs.

## SCD Type 2

Silver is rebuilt deterministically from every distinct content version observed in Bronze. Versions are ordered by source update time with extraction/save time as fallback. `valid_from` is the effective timestamp, `valid_to` is the next observed version timestamp, and `is_current` identifies the latest observed version. A resource that never changes during the observed period naturally has only one version; a change observed on a later run should result in multiple Silver versions.

## Startup and reset behavior

The ingestion notebook's startup cell ensures the layer schemas exist and removes only old prefixed duplicates when the corresponding schema-based replacement is already present. It never deletes current layer tables or Raw files. The standalone `nb_00_setup_cleanup` notebook is destructive only when the explicit reset token is supplied; it is a manual one-time reset utility and must never run in the recurring pipeline.

## Transformations and security

Spark performs JSON extraction and table conversion. Dataflows Gen2 is not used for JSON-to-table conversion.

Do not commit credentials, access tokens, Raw payloads, or extracted datasets. Notebook source and documentation belong in Git; runtime data belongs in the Fabric Lakehouse/Warehouse.
