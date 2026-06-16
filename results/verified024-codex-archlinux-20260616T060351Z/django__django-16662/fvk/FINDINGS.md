# FVK Findings

Status: constructed, not machine-checked.

## F-1: V0 module-only sorting violates the public ordering rule

Input:

```python
import datetime
from django.db import migrations, models
import time
```

Observed before V1: sorting only by `line.split()[1]` orders the keys as
`datetime`, `django.db`, and `time`, which can place a `from ... import ...`
line between plain imports.

Expected from intent I-2 and I-3:

```python
import datetime
import time
from django.db import migrations, models
```

Classification: code bug in the original implementation.

Status: resolved by V1. PO-2 and PO-3 show that the new key ranks `import`
before `from`, independent of module token.

## F-2: Full isort grouping is outside the public repair scope

Input:

```python
import datetime
import time
from django.db import migrations, models
```

Observed after V1: the writer still emits a single import block with no blank
line between standard-library imports and Django imports.

Expected by this issue: no blank-line grouping obligation. The public hint says
the accepted repair should be a small tweak rather than complicated full isort
compatibility.

Classification: rejected alternative, not a source defect for this task.

Status: no code change. This is tied to PO-5 and non-obligation N-1 in
`fvk/PROOF_OBLIGATIONS.md`.

## F-3: Equal-key tie ordering remains under-specified

Input example:

```python
from decimal import Decimal
from decimal import Context
```

Observed after V1: these lines have the same formal key
`(from, "decimal")`. The import collection is a set, so a deterministic
full-line order for equal keys is not specified by the current writer.

Expected by this issue: no public requirement names equal-key tie ordering; the
reported bug concerns plain imports appearing after from-imports.

Classification: underspecified intent, not a V2 code bug.

Status: no code change. If future public intent requires full isort behavior,
add a secondary full-line key and update the spec.

## F-4: Sort key assumes generated import-line shape

Input outside the modeled domain:

```python
not_an_import_line
```

Observed after V1: `line.split()[1]` would not be a meaningful imported module
token for arbitrary strings.

Expected by the actual writer: this sorter receives generated import strings
from Django serializers and operation writers, each beginning with `import` or
`from`.

Classification: domain precondition, not a defect in the migration writer.

Status: encoded as PO-1. V1 does not widen the accepted domain and does not
change the preexisting `split()[1]` assumption.

## F-5: No source edit required after FVK audit

Input: any finite generated import set satisfying PO-1.

Observed after V1: the output is sorted by `(style_rank, module_token)`.

Expected by I-2: all plain imports precede all from-imports in the generated
import block, while preserving the previous module-token sort within each style.

Classification: confirmation finding.

Status: V1 stands. PO-2 through PO-6 discharge the required behavior.
