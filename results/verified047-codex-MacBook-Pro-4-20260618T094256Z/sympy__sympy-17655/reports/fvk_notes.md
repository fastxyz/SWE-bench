# FVK Notes

Status: constructed, not machine-checked.

I used FVK to audit V1 and wrote the artifact package under `fvk/`.

## Decision

V1 stands unchanged. I did not edit source under `repo/` during this pass.

## Trace To Artifacts

- `fvk/INTENT_SPEC.md` fixes the public intent: scalar-left `Point`
  multiplication should match scalar-right multiplication, and the two issue
  expressions should give the same result.
- `fvk/point-scalar-mul-spec.k` contains the formal claims. `POINT-RMUL` and
  `POINT-RMUL-DIRECT` model the priority dispatch into `Point.__rmul__` and the
  delegation to point coordinate scaling. `ISSUE-EXAMPLE` models the reported
  expression shape.
- `fvk/SPEC_AUDIT.md` records that those formal claims match the public intent.
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md` records the regression audit for the V1
  `_op_priority` change and the reflected add/sub/div guards.
- `fvk/FINDINGS.md` records no concrete counterexample or unmet proof obligation
  requiring a code edit. Its only caveat is that the proof is constructed, not
  machine-checked, because K execution is forbidden in this session.

## Why No V2 Edit Was Applied

The revision discipline requires leaving V1 in place unless the audit produces a
specific failing obligation and a regression-free minimal edit. The FVK findings
do not contain such a failure. The artifacts instead support that V1's structure
is necessary: `_op_priority` lets SymPy scalar `Expr` operands defer to
`Point.__rmul__`, `__rmul__` reuses the existing coordinate-scaling
implementation, and the reflected add/sub/div overrides prevent the priority
change from recursing through inherited `GeometryEntity` methods.

No tests, Python code, or K tooling were run.
