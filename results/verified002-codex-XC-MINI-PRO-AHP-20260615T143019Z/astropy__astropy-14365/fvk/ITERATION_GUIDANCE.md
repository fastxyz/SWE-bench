# Iteration Guidance

Status: V1 confirmed for the audited intent; no source change made in the FVK
pass.

## Decision

Keep V1 unchanged.

F-001 is discharged by PO-001 and PO-002: the scoped inline case-insensitive
regex group directly fixes the reported lowercase `read serr` failure.
F-002 is discharged by PO-003: downstream err-spec handling already normalizes
the error command keyword. F-004 is discharged by PO-004 and PO-005: uppercase
behavior and public API shape are preserved.

## Recommended Next Development Steps

- In a normal execution environment, run the QDP tests and add public coverage
  for lowercase and mixed-case supported error commands.
- Machine-check the constructed FVK artifacts with the commands listed in
  `PROOF.md` before treating any tests as proof-redundant.
- If future public requirements ask for more of the QDP command language, treat
  F-003 as the starting point for a separate parser expansion. Do not infer that
  broader support from this issue alone.

## No-Exec Constraint

No tests, Python code, `kompile`, or `kprove` were run during this pass, in
accordance with the benchmark instructions.
