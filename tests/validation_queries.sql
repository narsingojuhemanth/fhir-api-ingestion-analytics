-- Run these queries in the Lakehouse SQL analytics endpoint where supported,
-- or adapt them to Spark SQL in a Fabric notebook.
-- Table names are unqualified Lakehouse table names.

-- 1. Audit trail by resource/run; all four resource types should appear after pipeline runs.
SELECT resource_type, run_id, run_status,
       COUNT(*) AS page_or_attempt_rows,
       MIN(api_call_timestamp) AS first_api_call_utc,
       MAX(saved_timestamp) AS last_saved_utc
FROM fhir_ingestion_audit
GROUP BY resource_type, run_id, run_status
ORDER BY resource_type, first_api_call_utc;

-- 2. Current source watermarks.
SELECT resource_type, last_successful_source_updated_utc,
       last_successful_run_id, watermark_updated_at_utc
FROM fhir_ingestion_watermarks
ORDER BY resource_type;

-- 3. Bronze counts per resource (run separately for tables that exist).
SELECT COUNT(*) AS rows, COUNT(DISTINCT resource_id) AS distinct_resources
FROM bronze_fhir_patient;
SELECT COUNT(*) AS rows, COUNT(DISTINCT resource_id) AS distinct_resources
FROM bronze_fhir_encounter;
SELECT COUNT(*) AS rows, COUNT(DISTINCT resource_id) AS distinct_resources
FROM bronze_fhir_observation;
SELECT COUNT(*) AS rows, COUNT(DISTINCT resource_id) AS distinct_resources
FROM bronze_fhir_condition;

-- 4. Bronze should not have duplicate content versions for a resource.
SELECT resource_type, resource_id, content_hash, COUNT(*) AS copies
FROM bronze_fhir_patient
GROUP BY resource_type, resource_id, content_hash
HAVING COUNT(*) > 1;

-- 5. SCD2 current rows: each resource ID should have at most one current version.
SELECT resource_id, SUM(CASE WHEN is_current THEN 1 ELSE 0 END) AS current_versions
FROM silver_fhir_patient
GROUP BY resource_id
HAVING SUM(CASE WHEN is_current THEN 1 ELSE 0 END) <> 1;

-- Run the same check for silver_fhir_encounter, silver_fhir_observation,
-- and silver_fhir_condition.

-- 6. Invalid SCD2 intervals should return no rows.
SELECT resource_id, valid_from, valid_to
FROM silver_fhir_patient
WHERE valid_to IS NOT NULL AND valid_from > valid_to;

-- 7. Gold current-state counts.
SELECT COUNT(*) AS current_patients FROM gold_fhir_patient;
SELECT COUNT(*) AS current_encounters FROM gold_fhir_encounter;
SELECT COUNT(*) AS current_observations FROM gold_fhir_observation;
SELECT COUNT(*) AS current_conditions FROM gold_fhir_condition;

-- 8. Warehouse views (run against wh_fhir_assignment after Warehouse load).
-- SELECT TOP 20 * FROM dbo.vw_gold_patient;
-- SELECT TOP 20 * FROM dbo.vw_gold_encounter;
-- SELECT TOP 20 * FROM dbo.vw_gold_observation;
-- SELECT TOP 20 * FROM dbo.vw_gold_condition;
