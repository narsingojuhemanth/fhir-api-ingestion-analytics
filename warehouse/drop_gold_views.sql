/*
Optional manual cleanup in wh_fhir_assignment.
Run only if these assessment views already exist and you intentionally want
to remove them before recreating the views from create_gold_views.sql.

This script does not delete any Lakehouse Gold data.
*/
DROP VIEW IF EXISTS dbo.vw_Patient;
GO
DROP VIEW IF EXISTS dbo.vw_Encounter;
GO
DROP VIEW IF EXISTS dbo.vw_Observation;
GO
DROP VIEW IF EXISTS dbo.vw_Condition;
GO
