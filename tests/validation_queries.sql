-- Run these queries in the Spark notebook as Spark SQL if the Lakehouse SQL
-- analytics endpoint does not support a given metadata query.
-- Schema-based Lakehouse tables:
--   bronze.Patient / Encounter / Observation / Condition
--   silver.Patient / Encounter / Observation / Condition
--   gold.Patient / Encounter / Observation / Condition

-- 1. Audit trail by resource/run.
SELECT resource_type, run_id, run_status,
       COUNT(*) AS page_or_attempt_rows,
       MIN(api_call_timestamp) AS first_api_call_utc,
       MAX(saved_timestamp) AS last_saved_utc
FROM dbo.fhir_ingestion_audit
GROUP BY resource_type, run_id, run_status
ORDER BY resource_type, first_api_call_utc;

-- 2. Current source watermarks.
SELECT resource_type, last_successful_source_updated_utc,
       last_successful_run_id, watermark_updated_at_utc
FROM dbo.fhir_ingestion_watermarks
ORDER BY resource_type;

-- 3. Bronze counts and distinct resource IDs.
SELECT COUNT(*) AS rows, COUNT(DISTINCT resource_id) AS distinct_resources FROM bronze.Patient;
SELECT COUNT(*) AS rows, COUNT(DISTINCT resource_id) AS distinct_resources FROM bronze.Encounter;
SELECT COUNT(*) AS rows, COUNT(DISTINCT resource_id) AS distinct_resources FROM bronze.Observation;
SELECT COUNT(*) AS rows, COUNT(DISTINCT resource_id) AS distinct_resources FROM bronze.Condition;

-- 4. Bronze should not have duplicate content versions for a resource.
SELECT resource_type, resource_id, content_hash, COUNT(*) AS copies
FROM bronze.Patient
GROUP BY resource_type, resource_id, content_hash
HAVING COUNT(*) > 1;

-- Repeat the above for bronze.Encounter, bronze.Observation, bronze.Condition.

-- 5. SCD2 current rows: each resource ID should have exactly one current version.
SELECT resource_id, SUM(CASE WHEN is_current THEN 1 ELSE 0 END) AS current_versions
FROM silver.Patient
GROUP BY resource_id
HAVING SUM(CASE WHEN is_current THEN 1 ELSE 0 END) <> 1;

-- Repeat for silver.Encounter, silver.Observation, silver.Condition.

-- 6. Invalid SCD2 intervals should return no rows.
SELECT resource_id, valid_from, valid_to
FROM silver.Patient
WHERE valid_to IS NOT NULL AND (valid_from IS NULL OR valid_from >= valid_to);

-- Repeat for silver.Encounter, silver.Observation, silver.Condition.

-- 7. Gold current-state counts.
SELECT COUNT(*) AS patients FROM gold.Patient;
SELECT COUNT(*) AS encounters FROM gold.Encounter;
SELECT COUNT(*) AS observations FROM gold.Observation;
SELECT COUNT(*) AS conditions FROM gold.Condition;

-- 8. Run these in wh_fhir_assignment after executing warehouse/create_gold_views.sql:
-- SELECT TOP 20 * FROM dbo.vw_Patient;
-- SELECT TOP 20 * FROM dbo.vw_Encounter;
-- SELECT TOP 20 * FROM dbo.vw_Observation;
-- SELECT TOP 20 * FROM dbo.vw_Condition;
