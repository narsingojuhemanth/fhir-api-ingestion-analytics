# Notebooks

| Notebook | Purpose | How it is used |
|---|---|---|
| `nb_01_fhir_ingestion.ipynb` | API pagination, Raw response storage, Bronze load, audit, watermark | Called four times by the pipeline with `resource_type` set to Patient, Encounter, Observation, or Condition |
| `nb_02_silver_scd2.ipynb` | Clean/deduplicate Bronze and build Silver SCD Type 2 history | Runs after all four resource ingestions |
| `nb_03_gold_analytics.ipynb` | Build current-state Gold analytical tables | Runs after Silver succeeds |
| `nb_04_validation.ipynb` | Check metadata, duplicates, SCD Type 2 intervals, Gold IDs, Raw sidecars, audit, and watermarks | Run manually after a successful pipeline execution |

Attach `lh_fhir_assignment` as the default Lakehouse for all four notebooks. Mark the first cell of the ingestion notebook as the Fabric parameter cell. See [the pipeline setup guide](../pipelines/fabric_pipeline_setup.md) for activity names and parameters.
