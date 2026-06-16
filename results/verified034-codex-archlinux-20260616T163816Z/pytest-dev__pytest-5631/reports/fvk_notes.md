# FVK Notes

Status: constructed, not machine-checked. No tests, Python code, or K tooling
were run.

## Decision Summary

I kept the V1 production source unchanged.

The reason is traceable to `fvk/FINDINGS.md` and
`fvk/PROOF_OBLIGATIONS.md`: F-001 identifies the original equality-based
membership bug, and PO-001 is discharged by V1's identity-only predicate
`any(p.new is s for s in sentinels)`. That predicate removes the reported
`ValueError` mechanism for array-like explicit `new=` values without weakening
mock argument counting.

## Source Code Decisions

`repo/src/_pytest/compat.py`

- Kept unchanged from V1 because PO-001 through PO-004 discharge the intended
  behavior: explicit non-sentinel `new=` values are not equality-compared or
  counted, while actual `DEFAULT` sentinels still count.
- Kept the existing `if not patchings: return 0` and no-loaded-mock fallback
  because PO-005 and PO-006 confirm those branches were not implicated by the
  issue and V1 did not alter them.
- Did not add a NumPy-specific branch because F-001 and PO-001 generalize the
  bug to arbitrary explicit `new=` values with unsafe or non-scalar equality.
- Did not replace the fix with `try`/`except ValueError` because PO-001 requires
  avoiding equality dispatch itself, not merely catching one failure mode after
  dispatch.
- Did not perform unrelated cleanup because F-004 and PO-007 found no public
  compatibility problem or additional source requirement.

## Artifact Decisions

`fvk/SPEC.md`

- Records the public intent ledger, formal English spec, adequacy audit, and
  compatibility audit. This traces the spec to the issue text, helper purpose,
  public mock integration behavior, and the no-API-change frame condition.

`fvk/FINDINGS.md`

- Records F-001 as resolved by V1 and F-002/F-003 as confirmed compatibility
  properties. F-005 and F-006 document residual proof status and model boundary
  without requiring a source change.

`fvk/PROOF_OBLIGATIONS.md`

- States the obligations used to decide whether V1 stands. PO-001 is the core
  safety obligation; PO-002 through PO-004 cover cardinality correctness;
  PO-005 through PO-007 cover frame behavior; PO-008 covers model adequacy.

`fvk/PROOF.md`

- Provides the constructed proof sketch and the exact K commands to run later.
  It also records that no test deletion is justified because the proof was not
  machine-checked.

`fvk/ITERATION_GUIDANCE.md`

- Explains why no V2 code edit is needed and lists focused future test work for
  a normal development environment.

`fvk/mini-patchcount.k` and `fvk/num-mock-patch-args-spec.k`

- Provide the formal-core support requested by the FVK method. They model the
  property under audit: identity-based membership over patch metadata.

## Assumptions

- `mock.DEFAULT` and `unittest.mock.DEFAULT` are singleton sentinel objects, so
  identity comparison is the intended way to recognize them.
- Explicit `new=` values do not create generated mock arguments for pytest to
  remove unless the explicit value is actually the `DEFAULT` sentinel.
- The formal model intentionally abstracts away full Python and NumPy semantics;
  this is adequate for the audited property because the proof obligation is to
  avoid using those equality semantics in the sentinel predicate.
