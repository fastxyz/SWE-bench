# Iteration Guidance

Status: V1 stands unchanged.

## Decision

Do not edit production source beyond the existing V1 patch. F-1 is resolved by
PO-2 through PO-6, and no open finding identifies a code defect under the public
intent.

## Why No V2 Source Edit Is Needed

The central public obligation is PO-3: plain imports must precede from-imports.
V1 satisfies this by making import style the primary sort key. PO-4 confirms the
previous module-token sorting is preserved within each style. PO-5 confirms the
change is local to ordering and does not affect import collection or rendering
structure.

F-2 was considered and rejected because full isort grouping is explicitly beyond
the small-tweak scope of the issue. F-3 was considered and left unchanged because
equal-key tie ordering has no public intent support in this task.

## Future Work If Intent Expands

If a later public issue requires full isort output, add separate obligations for
standard-library/third-party/local grouping, blank-line section separators, and
full-line tie ordering. That would be a different patch from this issue.

If a later public issue requires deterministic ordering for same-style,
same-module imports, add the full import line as a secondary key after
`module_token`.

## Suggested Tests For A Normal Development Environment

Do not edit tests in this benchmark. In a normal Django development workflow, a
focused regression test would construct generated imports containing:

```python
import datetime
from django.db import migrations, models
import time
```

and assert that the generated migration output places both plain imports before
the `from django.db ...` line.
