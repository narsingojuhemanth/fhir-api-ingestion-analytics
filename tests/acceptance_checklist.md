# Assessment Acceptance Checklist

Use this checklist for end-to-end validation before submitting.

## Source/API
- [ ] HAPI FHIR R4 used.
- [ ] Patient, Encounter, Observation, and Condition each return successful searchset Bundles.
- [ ] Pagination follows server-provided `next` URLs.
- [ ] Incremental filter `_lastUpdated=ge...` tested for all four resources.
- [ ] Successful data ingestion evidence retained for 2–3 days (separate successful runs).

## Raw
- [ ] Original successful API response body saved without parsing/re-serializing.
- [ ] Path is bucketed by resource and extraction date.
- [ ] Each run has a unique run ID folder.
- [ ] Page metadata sidecar records URL, API-call/extraction timestamp, save timestamp, status, entry count, and Raw path.
- [ ] Failed/incomplete runs do not advance the source watermark.

## Bronze
- [ ] Schema-based Delta tables: `bronze.Patient`, `bronze.Encounter`, `bronze.Observation`, `bronze.Condition`.
- [ ] Required metadata columns `extraction_timestamp` and `api_url_or_params` present.
- [ ] `source_last_updated` and content hash present.
- [ ] Merge deduplicates identical resource content versions but permits changed hashes as new versions.

## Silver / SCD Type 2
- [ ] Spark cleaning/deduplication is implemented.
- [ ] Schema-based tables exist: `silver.Patient`, `silver.Encounter`, `silver.Observation`, `silver.Condition`.
- [ ] `valid_from`, `valid_to`, and `is_current` exist.
- [ ] At most one current version per resource ID.
- [ ] Changed resource content across observed loads produces multiple retained versions and closes the former current interval.

## Gold / Warehouse
- [ ] Schema-based Gold tables exist: `gold.Patient`, `gold.Encounter`, `gold.Observation`, `gold.Condition`.
- [ ] Gold keys are non-null and unique; important field population checked.
- [ ] Warehouse `wh_fhir_assignment` exists.
- [ ] Warehouse views `dbo.vw_Patient`, `dbo.vw_Encounter`, `dbo.vw_Observation`, `dbo.vw_Condition` query successfully against Lakehouse Gold via three-part naming.

## Orchestration and submission
- [ ] Fabric pipeline activities enforce Patient → Encounter → Observation → Condition.
- [ ] Silver runs only after all ingestion activities succeed.
- [ ] Gold runs only after Silver succeeds.
- [ ] Pipeline/table lineage and runbook documented.
- [ ] Fabric notebooks exported to `notebooks/`.
- [ ] GitHub contains code/docs only—no raw payloads or secrets.
- [ ] ZIP backup exported and verified.
- [ ] Optional XML and Power BI extensions considered only after mandatory criteria pass.
