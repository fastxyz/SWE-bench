# Proof Obligations

Status: constructed, not machine-checked.

## PO-1: Generated Import-Line Domain

Claim: every line passed to the ordering step is a generated import string whose
first token is `import` or `from`, and whose second token is the imported module
or package.

Evidence: `writer.py` adds strings like `from django.conf import settings` and
`from django.db import migrations`; serializers add strings like
`import datetime`, `from decimal import Decimal`, and `import <module>`.

Status: discharged as a domain precondition. This is the same domain assumed by
the preexisting `i.split()[1]` sort key.

## PO-2: V1 Key Encodes Import Style

Claim: V1 computes a key equivalent to:

```text
(line.split()[0] == "from", line.split()[1])
```

For generated import lines, the first component is `False` for plain
`import ...` lines and `True` for `from ... import ...` lines.

Status: discharged by direct source inspection of
`repo/django/db/migrations/writer.py`.

## PO-3: Plain Imports Precede From-Imports

Claim: for any generated plain import `p` and generated from-import `f`,
`sort_key(p) < sort_key(f)` regardless of their module tokens.

Reason: Python tuple ordering compares the first component first, and
`False < True`.

Status: discharged. This is the central issue obligation.

## PO-4: Module Ordering Is Preserved Within Each Import Style

Claim: if two generated import lines have the same style, V1 orders them by the
same `line.split()[1]` module/package token used before V1.

Status: discharged. V1 changes only the primary key component and preserves the
previous module-token sort as the secondary component.

## PO-5: Sorting Is a Frame-Preserving Reorder

Claim: sorting reorders the generated import lines but does not create or delete
import lines; the existing `django.db` migrations/models merge and manual
porting comments remain outside the key change.

Status: discharged by source inspection and the standard contract of Python
`sorted()` over a finite iterable. Full implementation proof of Python sorting
is part of the trusted base for this FVK run.

## PO-6: Concrete Issue Witness

Claim: for input lines:

```python
import datetime
from django.db import migrations, models
import time
```

V1 emits:

```python
import datetime
import time
from django.db import migrations, models
```

Status: discharged by PO-2, PO-3, and PO-4.

## PO-7: Public Compatibility

Claim: V1 does not change public APIs, method signatures, serializer return
shape, operation writer contracts, or migration file structure beyond import
line order.

Status: discharged by source diff. Only the local sort key in
`MigrationWriter.as_string()` changed.

## Non-Obligations

N-1. Blank-line grouping between standard-library, third-party, and local import
sections is not required by this issue.

N-2. Full-line deterministic ordering among distinct lines with identical style
and module tokens is not required by this issue.

N-3. Running or modifying tests is not part of this benchmark task.
