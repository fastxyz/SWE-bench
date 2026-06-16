# Iteration Guidance

Status: constructed, not machine-checked.

## Decision

V1 stands unchanged.

The FVK audit found the original defect at the same source point as V1:
`TypeSerializer.serialize()` emitted `models.Model` without returning the import
that binds `models`. PO-1 through PO-6 show that once this import token is
returned, the existing tuple, operation, and migration writer aggregation paths
produce a valid migration import section for the reported case.

## No Additional Source Edits

No additional production edit is recommended because:

- F-1 is resolved by V1.
- F-2 rejects a broader writer string-scanning patch as inconsistent with the
  serializer import-provenance design.
- F-3 confirms the downstream path already propagates the import after PO-1 is
  satisfied.
- PO-7 confirms public signatures, return shapes, and tests are preserved.

## Future Validation Commands

These commands are documented for a future environment with execution support;
they were not run here:

```sh
kompile fvk/mini-migration-serializer.k --backend haskell
kast --backend haskell fvk/migration-serializer-spec.k
kprove fvk/migration-serializer-spec.k
```

Expected result after machine checking: `#Top`.

## Suggested Public Test Shape

Do not modify tests in this benchmark task. In a normal development workflow,
the relevant regression test would construct or generate a migration whose
operation body contains:

```text
bases=(app.models.MyMixin, models.Model)
```

while no other serialized operation component independently requires
`from django.db import models`. The assertion should check that the generated
module is executable Python or that its imports include:

```text
from django.db import migrations, models
```
