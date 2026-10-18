# Fabric Notebook Import

Import the following four notebooks into workspace `ws_fhir_assessment` and attach the schema-enabled `lh_fhir_assignment` as the default Lakehouse:

1. `nb_01_fhir_ingestion.ipynb` → Fabric item name `nb_01_fhir_ingestion`
2. `nb_02_silver_scd2.ipynb` → Fabric item name `nb_02_silver_scd2`
3. `nb_03_gold_analytics.ipynb` → Fabric item name `nb_03_gold_analytics`
4. `nb_04_validation.ipynb` → Fabric item name `nb_04_validation`

The ingestion notebook has one parameter cell and a following schema-initialization cell. Keep the parameter cell tagged as a Fabric notebook parameter cell; the pipeline overrides `resource_type` on each of the first four activities.

## Execution order

The production pipeline runs:

Patient → Encounter → Observation → Condition → Silver SCD Type 2 → Gold tables.

Run `nb_04_validation` separately after a successful pipeline run. It is read-only by default.

The ingestion notebook creates schemas if they do not exist. It does not delete tables or Raw files. For a clean deployment, create a new workspace and Lakehouse rather than embedding destructive cleanup in a recurring pipeline.
