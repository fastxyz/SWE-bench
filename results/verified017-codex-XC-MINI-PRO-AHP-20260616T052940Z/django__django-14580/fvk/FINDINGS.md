# FVK Findings

Status: constructed, not machine-checked.

## F-1: V1 Fix Resolves the Reported Missing Import

Input:

```text
CreateModel(..., bases=(app.models.MyMixin, models.Model))
```

Observed in the public bug report before the fix:

```text
import app.models
from django.db import migrations
...
bases=(app.models.MyMixin, models.Model)
```

The migration body references `models.Model`, but `models` is not bound, so
loading the migration raises `NameError`.

Expected:

```text
import app.models
from django.db import migrations, models
...
bases=(app.models.MyMixin, models.Model)
```

Audit result: resolved by PO-1 through PO-6. V1 makes the serializer for
`models.Model` return `from django.db import models`; the existing tuple,
operation, and migration writer aggregation paths then propagate and render it.

## F-2: Import Provenance Belongs in the Serializer, Not String Scanning

Input:

```text
Any serializer result whose text contains a module-qualified reference.
```

Observed risk:

```text
If the writer had to scan rendered operation strings for "models.", imports
would be inferred from formatting rather than from serializer knowledge.
```

Expected:

```text
Each serializer returns the text and the import set needed by that text.
```

Audit result: PO-1 follows the existing serializer design shown by
`DeconstructableSerializer._serialize_path()`. No writer string-scanning change
is justified.

## F-3: No Additional Source-Code Gap Found

Input:

```text
models.Model in a bases tuple, with no field serializer independently adding
from django.db import models
```

Observed after V1 by source inspection:

```text
TypeSerializer -> TupleSerializer/BaseSequenceSerializer -> OperationWriter
-> MigrationWriter.as_string
```

Expected:

```text
The import token from TypeSerializer reaches the final migration imports.
```

Audit result: confirmed by PO-4 through PO-6. No additional production edit is
needed beyond V1.

## F-4: Proof Capability and Execution Boundary

Input:

```text
The FVK proof artifacts for this task.
```

Observed:

```text
The environment forbids running tests, Python, kompile, kast, or kprove.
```

Expected:

```text
Artifacts contain the exact commands and a constructed proof, but do not claim
machine-checked success.
```

Audit result: residual risk is limited to unexecuted proof/toolchain checking
and the mini-semantics abstraction. The findings do not depend on hidden tests
or execution results.

## F-5: Tests Remain Fixed and Unmodified

Input:

```text
Project test suite and hidden evaluator tests.
```

Observed:

```text
The task forbids modifying tests and provides no test results.
```

Expected:

```text
Production code and FVK/report artifacts only.
```

Audit result: no test files were edited. No test redundancy removal is
recommended because the proof is constructed, not machine-checked, and the task
explicitly fixes the test suite.
