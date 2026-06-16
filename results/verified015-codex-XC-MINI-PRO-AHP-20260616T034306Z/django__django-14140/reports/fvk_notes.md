# FVK Notes

## Summary

The FVK audit confirms that the V1 fix should stand unchanged. No production
source files were edited in V2.

## Decisions

Decision 1: keep the V1 conditional guard in `Q.deconstruct()`.

- Traced to `fvk/FINDINGS.md` F-001 and `fvk/PROOF_OBLIGATIONS.md` PO-2.
- Reason: the reported crash occurs because `Q(Exists(...)).deconstruct()`
  previously entered the single-child lookup-pair branch and indexed a
  non-subscriptable conditional expression. PO-2 proves that V1 routes
  conditional children through positional `args` and never indexes them.

Decision 2: do not remove the single-child kwargs special case.

- Traced to F-002 and PO-1.
- Reason: the issue statement and public tests both preserve
  `Q(x=1).deconstruct()` as `args == ()` and `kwargs == {'x': 1}`. Removing the
  special case would be broader than the accepted public-intent contract.

Decision 3: accept V1's handling of nested `Q` children.

- Traced to F-003 and PO-3.
- Reason: `Q.conditional` is true, so nested `Q` children follow the same
  positional path as conditional expression children. This preserves the public
  nested-`Q` behavior.

Decision 4: do not add a length-two tuple guard for arbitrary single children.

- Traced to F-004 and PO-6.
- Reason: inputs such as `Q(False)` remain unsupported. The FVK spec records
  this as an explicit scope boundary because the public hint says it is enough
  to handle conditional expressions while keeping the current output format.

Decision 5: do not add an `Exists`-specific branch.

- Traced to `fvk/SPEC.md` evidence entries E7-E8 and PO-2.
- Reason: Django already exposes the general `conditional` protocol used by
  `Q._combine()` and boolean expression operators. The fix should apply to all
  supported conditional expression children, not only `Exists`.

Decision 6: do not run or infer test results.

- Traced to F-005.
- Reason: the benchmark forbids Python, tests, and K tooling. The proof is
  constructed from source inspection and public intent only, so no test-removal
  recommendation is made.

## Changed Files

V2 added only FVK/reporting artifacts:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`
- `reports/fvk_notes.md`

The only production code change remains the V1 edit in
`repo/django/db/models/query_utils.py`.
