/*
Run this script in the SQL query editor for Warehouse wh_fhir_assignment
after the four Gold Lakehouse tables have been copied into dbo.

If your Fabric SQL editor does not accept CREATE OR ALTER VIEW, run each
CREATE VIEW statement after dropping the view if it already exists.
*/
CREATE OR ALTER VIEW dbo.vw_gold_patient
AS
SELECT
    patient_id, active, gender, birth_date, family_name, given_name,
    managing_organization_reference, deceased_boolean, source_last_updated,
    content_hash, valid_from, valid_to, is_current, ingestion_run_id, saved_timestamp
FROM dbo.gold_fhir_patient
WHERE is_current = 1;

CREATE OR ALTER VIEW dbo.vw_gold_encounter
AS
SELECT
    encounter_id, status, class_code, class_display, encounter_type_code,
    encounter_type_display, subject_reference, patient_id, period_start, period_end,
    service_provider_reference, source_last_updated, content_hash, valid_from,
    valid_to, is_current, ingestion_run_id, saved_timestamp
FROM dbo.gold_fhir_encounter
WHERE is_current = 1;

CREATE OR ALTER VIEW dbo.vw_gold_observation
AS
SELECT
    observation_id, status, code, code_display, category, subject_reference,
    patient_id, encounter_reference, effective_datetime, value_quantity, value_unit,
    value_string, interpretation, source_last_updated, content_hash, valid_from,
    valid_to, is_current, ingestion_run_id, saved_timestamp
FROM dbo.gold_fhir_observation
WHERE is_current = 1;

CREATE OR ALTER VIEW dbo.vw_gold_condition
AS
SELECT
    condition_id, clinical_status, verification_status, category, code, code_display,
    subject_reference, patient_id, encounter_reference, onset_datetime, recorded_date,
    source_last_updated, content_hash, valid_from, valid_to, is_current,
    ingestion_run_id, saved_timestamp
FROM dbo.gold_fhir_condition
WHERE is_current = 1;
