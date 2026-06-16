# FVK Specification: Migration Import Ordering

Status: constructed, not machine-checked.

## Scope

The verified unit is the generated migration import ordering step in
`MigrationWriter.as_string()`, after import strings have been collected, migration
function imports have been removed into comments, and the `django.db` migrations
import has been added or merged with `models`.

The observable is `items["imports"]`: a newline-joined list of generated import
lines. The proof models the sort key used for those lines; it does not model all
of migration rendering, operation serialization, or Python's full `sorted()`
implementation.

## Intent-Only Obligations

I-1. Source: `benchmark/PROBLEM.md`.
Quoted evidence: "Migration import ordering violates coding style and isort
defaults".
Obligation: generated migration import blocks must satisfy the import-style
ordering rule that the bug report identifies.
Status: encoded in PO-3 and the K claim `ORDERED-BY-STYLE-MODULE`.

I-2. Source: `benchmark/PROBLEM.md`.
Quoted evidence: "Place all import module statements before from module import
objects in each section."
Obligation: for any generated plain `import ...` line and generated
`from ... import ...` line in the same emitted import block, the plain import
line must appear first.
Status: encoded in PO-3.

I-3. Source: `benchmark/PROBLEM.md`.
Quoted evidence: the desired example orders `import datetime`, `import time`,
then `from django.db import migrations, models`.
Obligation: the concrete issue witness must produce that order.
Status: encoded in PO-6 and the K claim `ISSUE-WITNESS`.

I-4. Source: `benchmark/PROBLEM.md`.
Quoted evidence: "this is a small tweak" and "not worth adding complicated logic
to make them fully isort-compatible".
Obligation: preserve the existing generated migration import pipeline except for
the style-ordering tweak; do not add full isort grouping or a new dependency.
Status: encoded as frame condition PO-5 and finding F-2.

I-5. Source: `repo/django/db/migrations/writer.py` and serializers under
`repo/django/db/migrations/serializer.py`.
Quoted evidence: imports are strings such as `import datetime`,
`from decimal import Decimal`, `from django.db import models`, and
`from django.conf import settings`.
Obligation: the sort domain is generated import lines whose first token is
`import` or `from` and whose second token is the module/package token.
Status: encoded in PO-1.

## Formal Contract

For each generated import line `line`, define:

```text
style_rank(line) =
    0 if line.split()[0] == "import"
    1 if line.split()[0] == "from"

module_token(line) = line.split()[1]
sort_key(line) = (style_rank(line), module_token(line))
```

The generated import block must be the input import lines sorted in
nondecreasing `sort_key` order, with no dropped or newly introduced import lines
from the sort itself.

This entails:

1. Every plain `import ...` line precedes every `from ... import ...` line.
2. Within the same import style, the previous module/package alphabetical
   ordering is preserved.
3. The concrete issue witness renders as:

```python
import datetime
import time
from django.db import migrations, models
```

## Non-Obligations

The public issue does not require full isort compatibility, blank-line grouping
between standard-library and Django imports, or deterministic tie-breaking among
distinct import lines with the same style and module token. Those behaviors are
recorded in `fvk/FINDINGS.md` as non-blocking audit notes.

## K Artifacts

The constructed K core is:

- `fvk/mini-migration-imports.k`
- `fvk/migration-imports-spec.k`

The commands that would machine-check the constructed proof are recorded in
`fvk/PROOF.md`. They were intentionally not executed.
