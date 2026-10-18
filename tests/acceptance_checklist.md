# Assessment Acceptance Checklist

## Environment and source
- [ ] Fabric workspace and schema-enabled Lakehouse created.
- [ ] HAPI FHIR R4 API is used.
- [ ] Patient, Encounter, Observation, and Condition each return valid searchset Bundles.
- [ ] Pagination follows server-provided `next` URLs.

## Raw and Bronze
- [ ] Incremental ingestion runs on separate days across the required 2–3-day period.
- [ ] Original successful API response bodies are saved unchanged under date/resource/run folders.
- [ ] Metadata sidecars are saved separately from response bodies.
- [ ] Bronze Delta tables exist: `bronze.Patient`, `bronze.Encounter`, `bronze.Observation`, `bronze.Condition`.
- [ ] Each Bronze table includes `extraction_timestamp` and `api_url_or_params`.
- [ ] API-call time and saved time are persisted in the audit/sidecar metadata.
- [ ] Resource IDs, payload JSON, and content hashes are populated.
- [ ] Identical resource content versions do not create duplicate Bronze rows.
- [ ] Audit and watermark tables exist and contain run evidence.

## Silver and SCD Type 2
- [ ] Silver Delta tables exist: `silver.Patient`, `silver.Encounter`, `silver.Observation`, `silver.Condition`.
- [ ] Spark cleaning/deduplication is implemented; Dataflows Gen2 is not used for JSON-to-table conversion.
- [ ] `valid_from`, `valid_to`, and `is_current` are present.
- [ ] Each resource ID has exactly one current Silver version.
- [ ] Historical intervals are valid.
- [ ] A changed resource observed on a subsequent run is retained as a new version; the previous version is no longer current.

## Gold and Warehouse views
- [ ] Gold Delta tables exist: `gold.Patient`, `gold.Encounter`, `gold.Observation`, `gold.Condition`.
- [ ] Gold resource IDs are non-null and unique.
- [ ] Warehouse `wh_fhir_assignment` exists.
- [ ] Views `dbo.vw_Patient`, `dbo.vw_Encounter`, `dbo.vw_Observation`, and `dbo.vw_Condition` execute successfully.

## Orchestration and submission
- [ ] Pipeline activities are linked in exact order: Patient → Encounter → Observation → Condition → Silver → Gold.
- [ ] Pipeline succeeds end-to-end.
- [ ] Pipeline/table relationships and setup steps are documented.
- [ ] GitHub repository or ZIP includes notebooks, SQL, pipeline setup, validation, and docs.
- [ ] The repository contains no credentials, raw payloads, or extracted datasets.

## Optional only
- [ ] XML ingestion.
- [ ] One-page Power BI report using Gold.
