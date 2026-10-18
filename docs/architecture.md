# Architecture and Design

## Source

Public HAPI FHIR R4 base URL: https://hapi.fhir.org/baseR4

Required resources:
- Patient
- Encounter
- Observation
- Condition

The API returns FHIR searchset Bundles. Each Bundle can contain multiple resource entries and server-managed pagination links. The ingestion notebook follows the response's `link` entry whose relation is `next`; it does not synthesize page offsets.

## Data flow

1. **Raw** — the successful HTTP response body is written to Lakehouse Files without parsing/re-serializing it. A separate sidecar JSON file records request and save metadata.
2. **Bronze** — one Delta table per resource stores each distinct observed resource content version, a canonical JSON representation, a SHA-256 content hash, the original Raw file path, extraction metadata, and run ID.
3. **Silver** — Spark filters malformed rows, deduplicates identical content versions, and builds SCD Type 2 validity intervals from source `meta.lastUpdated` when available.
4. **Gold** — Spark parses commonly used resource fields into analytics-friendly current-state Delta tables.
5. **Warehouse** — `wh_fhir_assignment` exposes SQL views over the Lakehouse Gold tables using same-workspace three-part naming. The Gold data stays in the Lakehouse; it is not copied into a second set of Warehouse tables.

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

The same structure applies to Encounter, Observation, and Condition. Raw payloads and sidecar metadata are stored together but separately. Do not commit data files to GitHub.

## Metadata and audit

- `extraction_timestamp`: time the page request/extraction started.
- `api_url_or_params`: actual URL used for that page, including the server-generated next URL when applicable.
- `api_call_timestamp`: request-start timestamp stored in the page audit table.
- `saved_timestamp`: time after the Raw response body was written.
- `source_last_updated`: FHIR resource `meta.lastUpdated`, preserved for change detection.
- `content_hash`: SHA-256 hash of canonicalized resource JSON.
- `ingestion_run_id`: unique ID linking page files and resource records to a run.

Audit table: `fhir_ingestion_audit`.
Watermark table: `fhir_ingestion_watermarks`, one current watermark per resource.

## Incremental strategy

On first run, the ingestion notebook queries the most recent `initial_lookback_days` (default 3) by using FHIR `_lastUpdated=ge...`. After a successful run with source timestamps, it saves the maximum observed source `meta.lastUpdated` as the resource watermark. Subsequent runs start from that watermark minus `overlap_minutes` (default 5) to reduce boundary misses. Bronze MERGE keys on resource type, resource ID, and content hash, so overlap does not create duplicate content versions.

The ingestion notebook will not advance the watermark if pagination hits the configured safety limit or if the fetch/parse/load path fails. Raw pages already saved remain available for investigation and retry.

**Assessment evidence note:** the code supports repeated daily runs. To evidence the explicit 2–3-day requirement, retain successful audit rows from runs across 2–3 days; a single initial three-day lookback is not by itself evidence of separate daily runs.

## SCD Type 2

Silver is rebuilt deterministically from every unique content version observed in Bronze. Versions are ordered by source update time, with extraction/save time as a fallback. `valid_from` is the effective timestamp, `valid_to` is the next observed version timestamp, and `is_current` identifies the latest observed version. This preserves historical observed content versions; a resource that never changes during the observation period will naturally have only one version.

## Transformations

Spark performs JSON extraction and table conversion. Dataflows Gen2 is not used for JSON-to-table conversion, consistent with the assignment's restriction.

## Security

The HAPI endpoint used here is public. Do not commit credentials, access tokens, Raw payloads, or extracted datasets to this repository. The notebook code and documentation belong in Git; the data belongs in the Fabric Lakehouse/Warehouse.
