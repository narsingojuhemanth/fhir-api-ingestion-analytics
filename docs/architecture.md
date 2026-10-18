# Architecture

## Source

The project uses the public [HAPI FHIR R4 API](https://hapi.fhir.org/baseR4) to ingest Patient, Encounter, Observation, and Condition resources. Search results are FHIR Bundles; the ingestion notebook follows the server-provided `next` link for pagination.

## Data flow

```text
HAPI FHIR R4
    |
    v
Raw Bundle response files + metadata sidecars
    |
    v
Bronze Delta tables
    |
    v
Silver Delta tables with SCD Type 2 history
    |
    v
Gold current-state analytical tables
    |
    v
Warehouse views -> Power BI semantic model -> report
```

### Raw

Each successful API response body is saved unchanged under a resource/date/run folder:

```text
Files/raw/fhir/
  resource=Patient/
    extraction_date=YYYY-MM-DD/
      run_id=.../
        page_00001.json
        page_00001.metadata.json
```

The same folder pattern is used for Encounter, Observation, and Condition. Request and save metadata are stored in the separate sidecar.

### Bronze

The four Delta tables are `bronze.Patient`, `bronze.Encounter`, `bronze.Observation`, and `bronze.Condition`. Each stores resource identity, JSON content, content hash, source update time, extraction and save timestamps, request URL, Raw file path, and run ID. The merge key includes resource type, resource ID, and content hash to avoid duplicate copies of identical content versions.

### Silver

The four Silver tables clean malformed rows and remove duplicate payload versions. Distinct content hashes for the same resource are retained as SCD Type 2 versions, with `valid_from`, `valid_to`, and `is_current`. Source `meta.lastUpdated` is used as the version timestamp when available.

### Gold and reporting

Gold contains current-state analytical projections for the four resource types. Warehouse views in `wh_fhir_assignment` expose those tables as `dbo.vw_Patient`, `dbo.vw_Encounter`, `dbo.vw_Observation`, and `dbo.vw_Condition`. The views read from Lakehouse Gold; no duplicate Gold copy is maintained in the Warehouse. See [the view script](../warehouse/create_gold_views.sql) and [Power BI model guide](power_bi_model.md).

## Control tables and metadata

Control tables are `dbo.fhir_ingestion_audit` and `dbo.fhir_ingestion_watermarks` in the Lakehouse default schema.

The audit captures the resource, run and page, API call timestamp, extraction/save timestamps, requested URL, Raw path, HTTP status, record count, and status/error detail. The watermark records the latest successful source update checkpoint for each resource.

Required metadata includes `extraction_timestamp` and `api_url_or_params`. The implementation also records `api_call_timestamp`, `saved_timestamp`, `source_last_updated`, `content_hash`, and `ingestion_run_id`.

## Incremental ingestion

The first run uses the configured lookback period (three days by default). Later runs use the saved source watermark with a configurable overlap (five minutes by default). A failed request, load, or pagination-safety check must not advance the watermark. If a completed scan returns no resources, the checkpoint advances conservatively to the scan start minus the overlap; if returned resources lack source timestamps, the prior watermark is retained.

The three-day initial lookback does not replace the assignment's requirement to retain successful runs from separate days. Run history and audit evidence should reflect the actual execution dates.

## Orchestration

The Fabric pipeline uses success dependencies in this order:

1. Patient ingestion
2. Encounter ingestion
3. Observation ingestion
4. Condition ingestion
5. Silver SCD Type 2 transformation
6. Gold table creation

Run `nb_04_validation` separately after a successful pipeline execution. Spark notebooks perform JSON-to-table conversion; Dataflows Gen2 is not used for that conversion.
