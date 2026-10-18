# Power BI semantic model

## Tables

Build the semantic model from the four Warehouse views:

- `dbo.vw_Patient`
- `dbo.vw_Encounter`
- `dbo.vw_Observation`
- `dbo.vw_Condition`

## Relationships

Create three active, one-to-many relationships using `patient_id`.

| One side | Many side | Cardinality | Cross-filter direction |
|---|---|---|---|
| `vw_Patient[patient_id]` | `vw_Encounter[patient_id]` | 1:* | Single, Patient to Encounter |
| `vw_Patient[patient_id]` | `vw_Observation[patient_id]` | 1:* | Single, Patient to Observation |
| `vw_Patient[patient_id]` | `vw_Condition[patient_id]` | 1:* | Single, Patient to Condition |

Check that `vw_Patient[patient_id]` is unique. Relationship fields must use the same ID format on both sides; do not join on display names, status fields, or clinical codes. Some resource references may not match a Patient in the current public sample, so unmatched references should be reviewed rather than hidden.

## Report fields

These fields are available for report visuals. The actual visuals can be arranged to suit the report created in Power BI.

| Topic | Fields |
|---|---|
| Patient overview | `vw_Patient[patient_id]`, `gender`, `birth_date`, `active` |
| Encounters | `vw_Encounter[encounter_id]`, `period_start`, `period_end`, `status`, `class_display` |
| Observations | `vw_Observation[observation_id]`, `code_display`, `category`, `value_quantity`, `value_unit`, `effective_datetime` |
| Conditions | `vw_Condition[condition_id]`, `clinical_status`, `verification_status`, `code_display`, `recorded_date` |

Use distinct resource IDs for entity counts. Use `period_start`, `effective_datetime`, or `recorded_date` for time analysis only where the data is populated and valid.

## Source

All four views are defined in [`warehouse/create_gold_views.sql`](../warehouse/create_gold_views.sql). They read current rows from the Lakehouse Gold tables; no extra Gold copy is required for the semantic model.
