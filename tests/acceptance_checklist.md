# Submission checklist

## Source ingestion
- [ ] HAPI FHIR R4 is used for Patient, Encounter, Observation, and Condition.
- [ ] Pagination follows the server-provided `next` links.
- [ ] Original Bundle response bodies are saved unchanged under resource/date/run folders.
- [ ] Request metadata is stored separately from the response body.
- [ ] Bronze Delta tables have resource JSON, IDs, hashes, and required metadata.
- [ ] Audit and watermark tables contain run evidence.

## Silver and Gold
- [ ] Silver tables are cleaned and deduplicated.
- [ ] Silver includes `valid_from`, `valid_to`, and `is_current`.
- [ ] Each resource has no more than one current Silver version.
- [ ] When a real source change is observed, the older Silver version is retained.
- [ ] Gold resource IDs are non-null and unique.
- [ ] All required metadata columns are present.

## Pipeline, Warehouse, and Power BI
- [ ] Pipeline order is Patient → Encounter → Observation → Condition → Silver → Gold.
- [ ] Pipeline completes successfully.
- [ ] Validation notebook returns `OVERALL: PASS`.
- [ ] All four Warehouse views execute successfully.
- [ ] The semantic model has the three Patient-to-resource relationships.
- [ ] The Power BI report opens and displays its visuals.

## Evidence and delivery
- [ ] Capture the successful pipeline run.
- [ ] Capture the validation output.
- [ ] Capture the Warehouse view query results.
- [ ] Capture the semantic model relationships and report page.
- [ ] Keep run-history evidence for the actual dates the pipeline ran; do not present same-day runs as separate-day runs.
- [ ] Repository contains no credentials, raw FHIR payloads, or extracted datasets.
