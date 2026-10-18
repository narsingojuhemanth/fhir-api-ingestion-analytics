from __future__ import annotations

import ast
import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
NOTEBOOK_DIR = ROOT / "notebooks"

REQUIRED_NOTEBOOKS = [
    "nb_01_fhir_ingestion.ipynb",
    "nb_02_silver_scd2.ipynb",
    "nb_03_gold_analytics.ipynb",
    "nb_04_validation.ipynb",
]
REQUIRED_FILES = [
    "README.md",
    "docs/architecture.md",
    "docs/data_dictionary.md",
    "docs/pipeline_table_relationships.md",
    "docs/requirement_traceability.md",
    "pipelines/fabric_pipeline_setup.md",
    "warehouse/create_gold_views.sql",
    "tests/acceptance_checklist.md",
    "tests/validation_queries.sql",
]

errors: list[str] = []

for required in REQUIRED_FILES:
    if not (ROOT / required).is_file():
        errors.append(f"Missing required file: {required}")

for filename in REQUIRED_NOTEBOOKS:
    path = NOTEBOOK_DIR / filename
    if not path.is_file():
        errors.append(f"Missing notebook: notebooks/{filename}")
        continue

    try:
        notebook = json.loads(path.read_text(encoding="utf-8"))
    except Exception as exc:
        errors.append(f"Invalid JSON in notebooks/{filename}: {exc}")
        continue

    if notebook.get("nbformat") != 4:
        errors.append(f"Unsupported notebook format in notebooks/{filename}")

    for index, cell in enumerate(notebook.get("cells", [])):
        if cell.get("cell_type") != "code":
            continue
        source = cell.get("source", "")
        source_text = "".join(source) if isinstance(source, list) else str(source)
        if not source_text.strip():
            continue
        try:
            ast.parse(source_text, filename=f"{filename}:cell{index}")
        except SyntaxError as exc:
            errors.append(
                f"Python syntax error in {filename}, cell {index}, "
                f"line {exc.lineno}: {exc.msg}"
            )

# Ensure layer-table names are consistent across the notebook sources.
expected = {
    "bronze.Patient", "bronze.Encounter", "bronze.Observation", "bronze.Condition",
    "silver.Patient", "silver.Encounter", "silver.Observation", "silver.Condition",
    "gold.Patient", "gold.Encounter", "gold.Observation", "gold.Condition",
}
source_text = ""
for path in NOTEBOOK_DIR.glob("*.ipynb"):
    try:
        notebook = json.loads(path.read_text(encoding="utf-8"))
        source_text += "\n".join(
            "".join(cell.get("source", []))
            for cell in notebook.get("cells", [])
        )
    except Exception:
        pass

for table_name in expected:
    if table_name not in source_text and table_name.split(".")[1] not in source_text:
        errors.append(f"Expected schema/table reference not found in notebooks: {table_name}")

if errors:
    print("PROJECT STATIC VALIDATION FAILED")
    for error in errors:
        print(f"- {error}")
    sys.exit(1)

print("PROJECT STATIC VALIDATION PASSED")
print(f"Validated {len(REQUIRED_NOTEBOOKS)} notebook files and {len(REQUIRED_FILES)} required project files.")
print("Python syntax and notebook JSON are valid. This does not replace execution in Microsoft Fabric.")
