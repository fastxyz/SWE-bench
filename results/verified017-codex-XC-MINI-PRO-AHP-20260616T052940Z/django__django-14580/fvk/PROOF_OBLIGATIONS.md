# Proof Obligations

Status: constructed, not machine-checked.

## PO-1: `models.Model` Serialization Carries Its Import

For input type value `models.Model`, `TypeSerializer.serialize()` must return
the pair:

```text
("models.Model", {"from django.db import models"})
```

This obligation is intent-derived from INT-1, INT-2, and INT-4.

Discharge condition: the `models.Model` special case in
`TypeSerializer.serialize()` returns the import token along with the existing
serialization string.

## PO-2: Other Type Special Cases Are Preserved

For input type value `type(None)`, `TypeSerializer.serialize()` must continue to
return:

```text
("type(None)", set())
```

This obligation is a frame condition from the current public serializer contract
and existing public writer tests.

Discharge condition: no change to the `type(None)` special case.

## PO-3: Custom Importable Type Serialization Is Preserved

For an importable non-built-in type with module `M` and qualified name `Q`,
`TypeSerializer.serialize()` must continue to return:

```text
("%s.%s" % (M, Q), {"import %s" % M})
```

This obligation is a compatibility frame condition and supports the reported
`app.models.MyMixin` half of the bases tuple.

Discharge condition: no change to the general `hasattr(value, "__module__")`
branch.

## PO-4: Tuple Serialization Unions Item Imports

For a tuple containing values `v1, ..., vn`, tuple serialization must include
the union of all imports returned by serializing each item. In the reported
shape:

```text
(app.models.MyMixin, models.Model)
```

the import set must include both:

```text
import app.models
from django.db import models
```

This obligation is intent-derived from INT-3 and implementation-derived from
the serializer contract.

Discharge condition: `BaseSequenceSerializer.serialize()` continues to call
`imports.update(item_imports)` for every item, and PO-1 supplies the previously
missing item import.

## PO-5: Operation Serialization Propagates Argument Imports

For `CreateModel(..., bases=(app.models.MyMixin, models.Model))`,
`OperationWriter.serialize()` must propagate the imports returned by
`MigrationWriter.serialize()` for the `bases` tuple.

This obligation is intent-derived from INT-1 and implementation-derived from
the operation writer import aggregation path.

Discharge condition: the existing `_write()` path continues to update the
operation import set with `arg_imports`; no source change is needed if PO-1 is
met.

## PO-6: Migration Imports Bind `models` When Needed

If the aggregate import set contains:

```text
from django.db import models
```

then `MigrationWriter.as_string()` must render:

```text
from django.db import migrations, models
```

This obligation is intent-derived from INT-1 and INT-2, and implementation-
derived from the writer's existing merge behavior.

Discharge condition: the writer's existing import merge branch is reached once
PO-1 makes the import token present.

## PO-7: Public Compatibility Is Preserved

The fix must not change public method signatures, serializer return shape, or
test files.

Discharge condition: the source diff is limited to the import set returned by
one existing special case, and no test files are edited.
