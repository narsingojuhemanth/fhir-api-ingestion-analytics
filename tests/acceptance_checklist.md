# Assessment Acceptance Checklist

Use this checklist for end-to-end validation before submitting.

## Source/API
- [ ] HAPI FHIR R4 used.
- [ ] Patient, Encounter, Observation, and Condition each return successful FHIR searchset Bundles.
- [ ] Pagination follows server-provided `next` URLs.
- [ ] Incremental filter `_lastUpdated=ge...` tested for all four resources.
- [ ] Successful data ingestion evidence retained for 2–3 days (separate successful runs).

## Raw
- [ ] Original successful API response body saved unmodified.
- [ ] Path is bucketed by resource and extraction date.
- [ ] Each run has a unique run ID folder.
- [ ] Page metadata sidecar records request URL, API-call/extraction timestamp, save timestamp, status, entry count, and Raw path.
- [ ] Failed/incomplete runs do not advance the source watermark.

## Bronze
- [ ] One Delta table per required resource.
- [ ] Required metadata columns `extraction_timestamp` and `api_url_or_params` present.
- [ ] `source_last_updated` and content hash present.
- [ ] Merge deduplicates identical resource content versions but allows a changed hash to be retained as another version.

## Silver / SCD Type 2
- [ ] Spark cleaning/deduplication is implemented.
- [ ] Silver table exists per resource.
- [ ] `valid_from`, `valid_to`, and `is_current` fields exist.
- [ ] At most one current version per resource ID.
- [ ] When source content changes between observed loads, older versions remain and the prior current version is closed.

## Gold / Warehouse
- [ ] Analytics-oriented Gold Delta tables exist for all four resources.
- [ ] Current-state fields include stable IDs and useful resource attributes.
- [ ] Four Gold tables copied into `wh_fhir_assignment`.
- [ ] Four SQL views created and queried successfully.

## Orchestration and submission
- [ ] Fabric pipeline activity dependencies enforce Patient → Encounter → Observation → Condition.
- [ ] Silver transform occurs only after all four ingestions succeed.
- [ ] Gold transform occurs only after Silver succeeds.
- [ ] Warehouse table copies occur only after Gold succeeds.
- [ ] Pipeline/table relationships and runbook documented.
- [ ] Fabric notebooks exported to `notebooks/`.
- [ ] GitHub repository contains code/documentation only, no raw payloads or secrets.
- [ ] ZIP backup exported and opened to check its contents.
- [ ] Optional XML and Power BI extensions considered only after mandatory criteria pass.
