# Constructed Proof

Status: constructed, not machine-checked.

## Claims

The formal claims are in `fvk/migration-serializer-spec.k` and are proved over
the fragment semantics in `fvk/mini-migration-serializer.k`.

The claims cover:

- `(SERIALIZE-MODELS-MODEL)`: `ModelsModel` serializes to `models.Model` and
  imports `from django.db import models`.
- `(SERIALIZE-NONE-TYPE)`: `NoneType` serializes to `type(None)` and no imports.
- `(SERIALIZE-CUSTOM-TYPE)`: custom importable types serialize to
  `<module>.<qualname>` and import the module.
- `(SERIALIZE-REPORTED-BASES)`: the reported bases tuple serializes to
  `(app.models.MyMixin, models.Model)` and carries both required imports.
- `(RENDER-WITH-MODELS)`: an aggregate import set containing
  `from django.db import models` renders the combined Django import
  `from django.db import migrations, models`.
- `(RENDER-WITHOUT-MODELS)`: an aggregate import set without the models import
  renders `from django.db import migrations`.

## Proof Sketch

PO-1 is discharged directly by the first rewrite rule for `serializeType`:

```text
ModelsModel => ser("models.Model", {"from django.db import models"})
```

In the production code, this corresponds to the V1 change in
`TypeSerializer.serialize()`.

PO-2 and PO-3 are discharged by unchanged branches:

```text
NoneType => ser("type(None)", empty imports)
CustomType(M, Q) => ser(M + "." + Q, {"import " + M})
```

In the production code, these correspond to the unchanged `type(None)`,
builtins, and non-built-in type branches.

PO-4 is discharged by symbolic composition. For the reported bases tuple:

```text
serializeType(CustomType("app.models", "MyMixin"))
  => ser("app.models.MyMixin", {"import app.models"})

serializeType(ModelsModel)
  => ser("models.Model", {"from django.db import models"})

mergeTuple2(...)
  => ser("(app.models.MyMixin, models.Model)",
         {"import app.models", "from django.db import models"})
```

This mirrors `BaseSequenceSerializer.serialize()`, whose loop updates the tuple
import set with every item import.

PO-5 is discharged by source-level framing: `OperationWriter._write()` delegates
the `bases` tuple to `MigrationWriter.serialize()` and updates its operation
import set with `arg_imports`. V1 does not alter this path; once PO-1 supplies
the missing import, the path carries it forward.

PO-6 is discharged by the `renderDjangoDbImport` split:

```text
if imports contains "from django.db import models":
    "from django.db import migrations, models"
else:
    "from django.db import migrations"
```

This mirrors the existing `MigrationWriter.as_string()` branch that discards
`from django.db import models` and adds `from django.db import migrations,
models`.

PO-7 is discharged by diff inspection: no public signature or return shape is
changed. The only source change is the import set attached to the existing
`models.Model` serialization string.

## Adequacy Gate

The English meaning of the K claims is recorded in
`fvk/FORMAL_SPEC_ENGLISH.md` and compared against the intent-only spec in
`fvk/SPEC_AUDIT.md`.

Result: pass. The formal claims require exactly the missing binding described by
the public issue and preserve the unaffected serializer branches.

## Machine-Check Commands

These commands were not executed in this environment:

```sh
kompile fvk/mini-migration-serializer.k --backend haskell
kast --backend haskell fvk/migration-serializer-spec.k
kprove fvk/migration-serializer-spec.k
```

Expected successful machine-check result: `#Top`.

## Test Guidance

No test files were modified. No test deletion is recommended in this benchmark
workspace because the proof is constructed, not machine-checked, and the task
explicitly fixes the test suite.
