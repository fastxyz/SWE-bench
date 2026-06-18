# Findings

Status: constructed, not machine-checked.

## F1: V1 Satisfies The Public Issue Obligation

Classification: confirm V1 / no code bug found.

Evidence:

- `POINT-RMUL` shows scalar-left `exprMul(scalar(F), point(CS))` reaches
  `point(scale(CS, F))`.
- `ISSUE-EXAMPLE` shows the reported addition expression reaches the same
  coordinate-wise result as the working right-multiplication expression.
- `SPEC_AUDIT.md` marks the scalar-left and issue-expression obligations as
  pass.

Decision: keep V1 unchanged. There is no concrete counterexample in the FVK
audit that forces a source edit.

## F2: Priority Change Requires Frame Guards, And V1 Has Them

Classification: regression audit / no code bug found.

Evidence:

- `RADD-FRAME`, `RSUB-FRAME`, and `RDIV-FRAME` model the reflected operations
  affected by adding `_op_priority`.
- `PUBLIC_COMPATIBILITY_AUDIT.md` records that direct point reflected add/sub
  behavior is preserved for non-`Expr` operands, matching public tests.

Decision: keep V1 unchanged. Removing these guards would reintroduce recursion
through inherited `GeometryEntity` reverse methods once `_op_priority` is
present.

## F3: Machine Checking Is Not Performed

Classification: proof status caveat, not a code bug.

Evidence:

- `PROOF.md` emits the exact `kompile` and `kprove` commands.
- The user explicitly forbids running K framework tooling in this session.

Decision: label the proof package "constructed, not machine-checked" and do not
recommend removing tests unless a later run obtains `kprove` result `#Top`.
