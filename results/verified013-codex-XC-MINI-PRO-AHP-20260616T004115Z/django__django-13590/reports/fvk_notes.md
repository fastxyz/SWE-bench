# FVK Notes

## Decision

V1 stands unchanged. The audit found the original bug and confirmed that the V1
branch for tuple instances with `_fields` is the minimal source change needed to
meet the public intent.

## Trace to findings and obligations

- No additional code edit was made because F1 is resolved by PO2: named
  two-field tuples now use `type(value)(*resolved_values)`, removing the
  pre-fix single-generator constructor call.
- The recursive generator was kept because F2 and PO3 show it is the common
  mechanism that resolves every container element with the same context.
- The unpacking branch remains limited to named tuples because F3 and PO4 show
  unpacking every list or tuple would regress the existing iterable-constructor
  behavior.
- The method signature and downstream protocol were left unchanged because F4
  and PO5 show `build_filter()` and iterable lookups remain compatible.
- No tests or K tooling were run because PO7 requires proof honesty in this
  no-execution benchmark. F5 records the residual risk and test guidance.

## Source changes in the FVK phase

None. The only production source change remains the V1 edit in
`repo/django/db/models/sql/query.py`.

## Artifacts

The required FVK artifacts are:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

Supporting FVK adequacy and formal files were also added under `fvk/`.
