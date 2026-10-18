# Fabric Notebook Source

The files in this folder are Jupyter-format notebook source that can be imported into Microsoft Fabric or copied cell-by-cell.

## Notebook sequence

1. `nb_01_fhir_ingestion.ipynb` — parameterized Raw and Bronze ingestion for one resource per run. Configure the Notebook activity's `resource_type` parameter to Patient, Encounter, Observation, or Condition.
2. `nb_02_silver_scd2.ipynb` — Spark cleanup/deduplication and SCD Type 2 reconstruction for all four Bronze tables.
3. `nb_03_gold_analytics.ipynb` — current-state analytics Gold Delta tables for all four resources.

## Import into Fabric

1. In the `ws_fhir_assessment` workspace, use **Import notebook** and upload the required `.ipynb` file downloaded from GitHub. If your UI does not offer import, create/open a notebook and copy the source cells from the GitHub file.
2. Name the Fabric items `nb_01_fhir_ingestion`, `nb_02_silver_scd2`, and `nb_03_gold_analytics`.
3. Attach `lh_fhir_assignment` as the default Lakehouse to each imported notebook.
4. For the ingestion notebook, make sure the config cell with the default values is recognized as the notebook parameter cell.
5. Save each notebook before running it.

Importing a notebook file into Fabric does not create the Workspace Lakehouse or the Data Pipeline. Those are configured separately using `pipelines/fabric_pipeline_setup.md`.

## Runtime note

The notebooks are committed source, but successful execution must still be proven in the target Fabric environment. Run the ingestion notebook for each resource before running Silver, then run Gold. Review `tests/acceptance_checklist.md` and persist the run evidence.