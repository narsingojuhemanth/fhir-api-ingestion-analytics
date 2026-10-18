-- Run these against the Lakehouse SQL analytics endpoint or adapt to Spark SQL.
-- Run Warehouse-view checks separately in wh_fhir_assignment.

-- 1. Audit status and elapsed run window.
SELECT resource_type, run_id, run_status,
       COUNT(*) AS audit_rows,
       MIN(api_call_timestamp) AS first_api_call_utc,
       MAX(saved_timestamp) AS last_saved_utc
FROM dbo.fhir_ingestion_audit
GROUP BY resource_type, run_id, run_status
ORDER BY resource_type, first_api_call_utc;

-- 2. Current watermarks.
SELECT resource_type, last_successful_source_updated_utc,
       last_successful_run_id, watermark_updated_at_utc
FROM dbo.fhir_ingestion_watermarks
ORDER BY resource_type;

-- 3. Bronze counts and distinct IDs.
SELECT COUNT(*) AS rows, COUNT(DISTINCT resource_id) AS distinct_ids FROM bronze.Patient;
SELECT COUNT(*) AS rows, COUNT(DISTINCT resource_id) AS distinct_ids FROM bronze.Encounter;
SELECT COUNT(*) AS rows, COUNT(DISTINCT resource_id) AS distinct_ids FROM bronze.Observation;
SELECT COUNT(*) AS rows, COUNT(DISTINCT resource_id) AS distinct_ids FROM bronze.Condition;

-- 4. Exact duplicate resource content versions; every query should return no rows.
SELECT resource_id, content_hash, COUNT(*) AS copies
FROM bronze.Patient
GROUP BY resource_id, content_hash
HAVING COUNT(*) > 1;

SELECT resource_id, content_hash, COUNT(*) AS copies
FROM bronze.Encounter
GROUP BY resource_id, content_hash
HAVING COUNT(*) > 1;

SELECT resource_id, content_hash, COUNT(*) AS copies
FROM bronze.Observation
GROUP BY resource_id, content_hash
HAVING COUNT(*) > 1;

SELECT resource_id, content_hash, COUNT(*) AS copies
FROM bronze.Condition
GROUP BY resource_id, content_hash
HAVING COUNT(*) > 1;

-- 5. Invalid current-version counts; every query should return no rows.
SELECT resource_id, SUM(CASE WHEN is_current THEN 1 ELSE 0 END) AS current_versions
FROM silver.Patient
GROUP BY resource_id
HAVING SUM(CASE WHEN is_current THEN 1 ELSE 0 END) <> 1;

SELECT resource_id, SUM(CASE WHEN is_current THEN 1 ELSE 0 END) AS current_versions
FROM silver.Encounter
GROUP BY resource_id
HAVING SUM(CASE WHEN is_current THEN 1 ELSE 0 END) <> 1;

SELECT resource_id, SUM(CASE WHEN is_current THEN 1 ELSE 0 END) AS current_versions
FROM silver.Observation
GROUP BY resource_id
HAVING SUM(CASE WHEN is_current THEN 1 ELSE 0 END) <> 1;

SELECT resource_id, SUM(CASE WHEN is_current THEN 1 ELSE 0 END) AS current_versions
FROM silver.Condition
GROUP BY resource_id
HAVING SUM(CASE WHEN is_current THEN 1 ELSE 0 END) <> 1;

-- 6. Invalid SCD2 intervals; every query should return no rows.
SELECT resource_id, valid_from, valid_to
FROM silver.Patient
WHERE valid_to IS NOT NULL AND (valid_from IS NULL OR valid_from >= valid_to);

SELECT resource_id, valid_from, valid_to
FROM silver.Encounter
WHERE valid_to IS NOT NULL AND (valid_from IS NULL OR valid_from >= valid_to);

SELECT resource_id, valid_from, valid_to
FROM silver.Observation
WHERE valid_to IS NOT NULL AND (valid_from IS NULL OR valid_from >= valid_to);

SELECT resource_id, valid_from, valid_to
FROM silver.Condition
WHERE valid_to IS NOT NULL AND (valid_from IS NULL OR valid_from >= valid_to);

-- 7. Gold counts.
SELECT COUNT(*) AS patients FROM gold.Patient;
SELECT COUNT(*) AS encounters FROM gold.Encounter;
SELECT COUNT(*) AS observations FROM gold.Observation;
SELECT COUNT(*) AS conditions FROM gold.Condition;

-- 8. Run these in Warehouse wh_fhir_assignment after creating the views.
-- SELECT TOP (20) * FROM dbo.vw_Patient;
-- SELECT TOP (20) * FROM dbo.vw_Encounter;
-- SELECT TOP (20) * FROM dbo.vw_Observation;
-- SELECT TOP (20) * FROM dbo.vw_Condition;
