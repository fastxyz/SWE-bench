# ITERATION GUIDANCE

Status: constructed, not machine-checked. No tests or code were run.

## Decision

V1 stands unchanged. The FVK audit found that the current source satisfies the
issue-derived obligations PO-001 through PO-005 and the compatibility/frame
obligations PO-006 and PO-007.

## Why No Source Edit Was Made

- F-001 and PO-001 show that V1 fixes the reported frozen-environment case.
- F-002 and PO-002 show that V1 preserves rejection of PEP 420 namespace
  migrations packages.
- F-003 with PO-003 and PO-004 shows that non-package migrations modules remain
  unmigrated.
- F-004 and PO-005 show that normal package scanning is preserved.
- F-005 with PO-006 and PO-007 shows that the change is API-compatible and
  leaves unrelated loader branches framed.

## Recommended Follow-Up Tests

Do not edit tests in this benchmark. In a normal development workflow, add or
keep tests covering:

- a regular migrations package with no `__file__` and list-valued `__path__`
  scans for migrations;
- a namespace migrations package with no `__file__` and non-list `__path__`
  remains unmigrated;
- a migrations module file with no `__path__` remains unmigrated.

## Machine-Check Follow-Up

The constructed K artifacts can be checked later with:

```sh
# From fvk/
kompile mini-migration-loader.k --backend haskell
kprove migration-loader-spec.k
```

Do not treat test-removal recommendations as valid unless the K claims are
machine-checked and return `#Top`.

## Residual Risks

The proof models the issue-relevant import attributes, not all of Python's
import machinery or `pkgutil.iter_modules()`. This is intentional: the source
change only affects the branch deciding whether to scan. If a future issue asks
for broader frozen-environment support, audit other migration helpers
separately instead of widening this patch.
