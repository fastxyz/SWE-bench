# Public Evidence Ledger

Status: constructed, not machine-checked.

| ID | Source | Quoted evidence | Obligation |
| --- | --- | --- | --- |
| INT-1 | `benchmark/PROBLEM.md` | "Expected behavior: Django generates a migration file that is valid Python." | Generated references must have imports. |
| INT-2 | `benchmark/PROBLEM.md` | "`bases=(app.models.MyMixin, models.Model)`" followed by `NameError: name 'models' is not defined`. | `models.Model` in output requires an import that binds `models`. |
| INT-3 | `benchmark/PROBLEM.md` | "MyModel doesn't have fields from django.db.models and has custom bases." | The bases path must independently supply its imports. |
| INT-4 | `benchmark/PROBLEM.md` | "special casing of models.Model in TypeSerializer" | Audit `TypeSerializer` special cases directly. |
| INT-5 | `repo/tests/migrations/test_writer.py` | `safe_exec()` executes generated migration output. | Existing public tests treat migration output as executable Python. |
| IMPL-1 | `serializer.py` | `_serialize_path()` returns `models.X` with `from django.db import models`. | Serializer-level import provenance is the local design. |
| IMPL-2 | `writer.py` | `if "from django.db import models" in imports:` then add `from django.db import migrations, models`. | Writer already renders the desired import when the serializer supplies it. |
