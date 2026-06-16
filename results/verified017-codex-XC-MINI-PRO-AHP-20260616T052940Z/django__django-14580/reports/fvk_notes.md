# FVK Notes

## Decision

V1 stands unchanged. The audit did not surface a source-code problem beyond the
one V1 already fixed.

## Trace to Findings and Proof Obligations

F-1 maps to PO-1 through PO-6. The reported migration body contains
`models.Model`; PO-1 supplies `from django.db import models` at the serializer
source, PO-4 unions it through tuple serialization, PO-5 propagates it through
operation serialization, and PO-6 renders `from django.db import migrations,
models`.

F-2 maps to PO-1 and PO-7. I kept the fix in `TypeSerializer.serialize()` rather
than adding writer-level string scanning because the serializer contract already
pairs text with required imports. This preserves caller APIs and avoids a
formatting-dependent import inference pass.

F-3 maps to PO-4 through PO-6. Source inspection showed the downstream path
already propagates item imports once `models.Model` contributes its import. No
additional edit to `BaseSequenceSerializer`, `OperationWriter`, or
`MigrationWriter` is justified.

F-4 records the proof boundary. I wrote the `.k` artifacts and exact future
commands, but did not run tests, Python, `kompile`, `kast`, or `kprove`, because
the task forbids execution.

F-5 maps to PO-7. No test files were modified, and no test-removal recommendation
is made because the proof is constructed, not machine-checked.

## Code Changes During FVK

No source files under `repo/` were changed during this FVK pass. The existing V1
change in `repo/django/db/migrations/serializer.py` remains the production fix:
the `models.Model` special case now returns `["from django.db import models"]`
with the existing `"models.Model"` serialization string.

## Alternative Interpretations Rejected

I rejected treating `MigrationWriter` as the root fix point. The public issue
mentions `django.db.migrations.writer`, but the proof obligations localize the
lost information earlier: before V1, `TypeSerializer` emitted a string that
needed `models` while returning no import. By the time the writer receives the
aggregate imports, it can only render imports it was told about.

I rejected changing the serialized text to `django.db.models.Model`. That would
alter an established output form without needing to; PO-1 only requires the
missing import metadata for the existing `models.Model` text.

I rejected adding broader behavior around custom bases. PO-3 and PO-4 show that
custom type imports and tuple import unioning already satisfy the reported
custom-base side of the issue.

## Residual Risk

The FVK proof is constructed, not machine-checked. The mini-K semantics abstracts
the relevant migration import algebra rather than modeling all of Python or all
of Django migration rendering. That abstraction is adequate for the reported
defect because it preserves the discriminating property: whether a generated
body reference to `models.Model` is accompanied by an import binding `models`.
