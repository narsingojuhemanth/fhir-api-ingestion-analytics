/*
Run this script in the SQL query editor for Warehouse wh_fhir_assignment
after adding the Lakehouse SQL analytics endpoint lh_fhir_assignment via
the Explorer's + Warehouses action.

The Gold tables remain in the Lakehouse under the gold schema; these views
reference them directly using three-part names, avoiding a second data copy.
*/
CREATE OR ALTER VIEW dbo.vw_Patient
AS
SELECT
    patient_id, active, gender, birth_date, family_name, given_name,
    managing_organization_reference, deceased_boolean, source_last_updated,
    content_hash, valid_from, valid_to, is_current, ingestion_run_id, saved_timestamp
FROM lh_fhir_assignment.gold.Patient
WHERE is_current = 1;
GO

CREATE OR ALTER VIEW dbo.vw_Encounter
AS
SELECT
    encounter_id, status, class_code, class_display, encounter_type_code,
    encounter_type_display, subject_reference, patient_id, period_start, period_end,
    service_provider_reference, source_last_updated, content_hash, valid_from,
    valid_to, is_current, ingestion_run_id, saved_timestamp
FROM lh_fhir_assignment.gold.Encounter
WHERE is_current = 1;
GO

CREATE OR ALTER VIEW dbo.vw_Observation
AS
SELECT
    observation_id, status, code, code_display, category, subject_reference,
    patient_id, encounter_reference, effective_datetime, value_quantity, value_unit,
    value_string, interpretation, source_last_updated, content_hash, valid_from,
    valid_to, is_current, ingestion_run_id, saved_timestamp
FROM lh_fhir_assignment.gold.Observation
WHERE is_current = 1;
GO

CREATE OR ALTER VIEW dbo.vw_Condition
AS
SELECT
    condition_id, clinical_status, verification_status, category, code, code_display,
    subject_reference, patient_id, encounter_reference, onset_datetime, recorded_date,
    source_last_updated, content_hash, valid_from, valid_to, is_current,
    ingestion_run_id, saved_timestamp
FROM lh_fhir_assignment.gold.Condition
WHERE is_current = 1;
GO
