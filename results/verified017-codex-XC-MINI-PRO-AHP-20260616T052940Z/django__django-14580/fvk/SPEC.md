# FVK Spec: Migration Serializer Import Provenance

Status: constructed, not machine-checked.

## Target

This audit targets the migration-generation path that produces a Python migration
module from a `CreateModel` operation whose `bases` include both a custom class
and `django.db.models.Model`.

The relevant production units are:

- `repo/django/db/migrations/serializer.py`
  - `TypeSerializer.serialize()`
  - `TupleSerializer` via `BaseSequenceSerializer.serialize()`
  - `serializer_factory()`
- `repo/django/db/migrations/writer.py`
  - `OperationWriter.serialize()`
  - `MigrationWriter.as_string()`
- `repo/django/db/migrations/operations/models.py`
  - `CreateModel.deconstruct()`

## Public Intent Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| INT-1 | `benchmark/PROBLEM.md` | "Expected behavior: Django generates a migration file that is valid Python." | Any identifier emitted into a generated migration body must be bound by an import or definition in that migration module. | Encoded in PO-1 through PO-5. |
| INT-2 | `benchmark/PROBLEM.md` | The reported generated migration contains `bases=(app.models.MyMixin, models.Model)` and fails with `NameError: name 'models' is not defined`. | If serialization emits `models.Model`, generated imports must bind `models`. | Encoded in PO-1 and PO-5. |
| INT-3 | `benchmark/PROBLEM.md` public hint | "It's due to the fact that MyModel doesn't have fields from django.db.models and has custom bases." | The import obligation must not depend on some unrelated field serializer adding `from django.db import models`. | Encoded in PO-2 through PO-4. |
| INT-4 | `benchmark/PROBLEM.md` public hint | "It looks like an issue with special casing of models.Model in TypeSerializer." | The special case for `models.Model` is a public-intent localization candidate and must be audited directly. | Encoded in PO-1. |
| INT-5 | Existing public test helper in `repo/tests/migrations/test_writer.py` | `safe_exec()` executes generated migration strings and fails on exceptions. | Migration writer output is intended to be executable Python, not only visually plausible text. | Supporting evidence for INT-1; no test files changed. |
| IMPL-1 | `serializer.py` | `_serialize_path("django.db.models.X")` returns `models.X` plus `from django.db import models`. | Existing serializer design carries imports alongside strings; source of import metadata is serializers. | Used as implementation evidence for PO-1 and rejected writer-string-scanning alternative. |
| IMPL-2 | `writer.py` | `MigrationWriter.as_string()` merges `from django.db import models` into `from django.db import migrations, models`. | Downstream import rendering already handles the correct import token if upstream serializers return it. | Used as implementation evidence for PO-5. |

## Domain

The verified domain is the partial-correctness slice for serializable migration
values handled by Django's existing serializer registry, specifically:

- `models.Model` as a Python type value;
- custom importable type values represented by module and qualified name;
- tuples of such values used as `CreateModel.bases`;
- operation import sets consumed by `MigrationWriter.as_string()`.

Out of scope for this FVK pass:

- whether arbitrary import strings point to importable modules at runtime;
- model autodetection correctness beyond the `bases` values it hands to
  `CreateModel`;
- file-system writes and migration loader behavior;
- termination, since the audited code has finite loops over finite Python
  collections and this pass is partial correctness.

## Intended Contract

1. `TypeSerializer.serialize(models.Model)` must return:
   - serialized text: `models.Model`;
   - imports containing exactly the binding needed for that text:
     `from django.db import models`.

2. `TypeSerializer.serialize(type(None))` remains unchanged:
   - serialized text: `type(None)`;
   - no imports.

3. Serialization of a custom importable type remains unchanged:
   - serialized text: `<module>.<qualname>`;
   - imports containing `import <module>`.

4. Tuple or sequence serialization must union the import sets returned by every
   serialized item. Therefore a bases tuple containing both a custom mixin and
   `models.Model` must carry both `import app.models` and
   `from django.db import models`.

5. `OperationWriter.serialize()` must propagate the imports returned by
   `MigrationWriter.serialize()` for operation arguments, including non-expanded
   tuple arguments such as `bases`.

6. `MigrationWriter.as_string()` must render `from django.db import migrations,
   models` whenever the aggregate operation/dependency import set contains
   `from django.db import models`; otherwise it renders `from django.db import
   migrations` for Django migration operations.

7. Frame conditions:
   - no public method signatures or return shapes are changed;
   - non-`models.Model` type serialization behavior is preserved;
   - no test files are modified.

## Formal Artifacts

The formal core for this spec is:

- `fvk/mini-migration-serializer.k`
- `fvk/migration-serializer-spec.k`

Exact commands to machine-check later, not executed in this environment:

```sh
kompile fvk/mini-migration-serializer.k --backend haskell
kast --backend haskell fvk/migration-serializer-spec.k
kprove fvk/migration-serializer-spec.k
```

Expected result after a successful machine check: `#Top`.
