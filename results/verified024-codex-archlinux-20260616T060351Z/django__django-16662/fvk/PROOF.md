# Constructed Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`,
Python, or test commands were executed.

## Claims

C-1 (`ORDERED-BY-STYLE-MODULE`): for any finite list of generated import lines,
`sortImports()` returns a permutation of the input whose keys are nondecreasing
under `(style_rank, module_token)`.

C-2 (`ISSUE-WITNESS`): the concrete issue input
`import datetime`, `from django.db import migrations, models`, `import time`
sorts to `import datetime`, `import time`,
`from django.db import migrations, models`.

The K model for these claims is in `fvk/mini-migration-imports.k` and
`fvk/migration-imports-spec.k`.

## Proof Sketch

1. By PO-1, each generated import line has a first token of either `import` or
   `from`, and the second token is the module/package token already used by the
   pre-V1 sort.

2. By PO-2, V1 computes the key
   `(line.split()[0] == "from", line.split()[1])`.

3. For any plain import `p`, `p.split()[0] == "from"` is `False`. For any
   from-import `f`, `f.split()[0] == "from"` is `True`.

4. Python tuple ordering compares the first component before the second, and
   booleans order as `False < True`. Therefore
   `sort_key(p) < sort_key(f)` for all generated plain imports `p` and
   generated from-imports `f`, regardless of module names. This proves PO-3.

5. When two import lines have the same style, their first key components are
   equal, so tuple ordering falls through to `line.split()[1]`. This is the same
   module/package token used by the original implementation. This proves PO-4.

6. Python `sorted()` over a finite iterable returns a permutation of the input
   ordered by the provided key. Since V1 changes only the key and not import
   collection, manual migration import filtering, or the `django.db` merge, the
   change is frame-preserving. This proves PO-5.

7. For the issue witness:

```text
import datetime                         -> (False, "datetime")
from django.db import migrations, models -> (True,  "django.db")
import time                             -> (False, "time")
```

Sorting lexicographically yields:

```text
(False, "datetime")
(False, "time")
(True,  "django.db")
```

This proves PO-6 and resolves F-1.

## Adequacy Check

The proof obligation exactly matches the public issue's positive requirement:
plain module imports must precede from-imports in generated migration import
blocks. The proof does not claim full isort behavior, blank-line section
grouping, or equal-key full-line tie ordering; those are either rejected by the
public hint or under-specified by the issue. See F-2, F-3, and N-1/N-2.

No public API or call protocol changed, so the compatibility obligation PO-7 is
discharged.

## Test Guidance

Do not remove tests. If the K artifacts are later machine-checked successfully,
unit tests that only assert the in-domain style-ordering property are logically
subsumed by C-1. Integration tests for full migration rendering, compatibility,
and import collection should be kept.

## Machine-Check Commands

These commands are recorded for a future environment with K installed. They were
not executed here.

```sh
kompile fvk/mini-migration-imports.k --backend haskell
kast --backend haskell fvk/migration-imports-spec.k
kprove fvk/migration-imports-spec.k
```

Expected outcome: `kprove` discharges the claims to `#Top`.

## Residual Risk

The proof relies on a small model of generated import lines and on the standard
contract of Python `sorted()`. It is a partial proof of the import-ordering
observable, not a proof of all migration rendering behavior or of full isort
compatibility.
