# FVK Notes

The FVK audit confirms the V1 source change and does not justify further
production edits.

## Decisions

- Kept the V1 qualified-property branch unchanged. Finding F-001 identifies the
  legacy `bar() (Foo property)` behavior as the reported bug, and proof
  obligations PO-1 and PO-3 are discharged by the current property-first return
  of `'%s (%s property)'`.
- Kept the V1 unqualified/module fallback change. PO-2 requires every
  property-option entry, not only the reproduced qualified entry, to avoid
  callable parentheses; F-003 records that V1 covers both unqualified fallback
  branches.
- Kept the property branch before classmethod/staticmethod branches. PO-3 says
  `:property:` must control the index shape whenever present; F-003 records no
  remaining branch that can bypass it.
- Did not change domain object registration from `method` to `property`.
  PO-7 requires cross-reference and inventory compatibility, and no Finding
  identifies object registration as part of the defect.
- Did not modify tests. F-002 marks the current public expectation
  `meth5() (Class property)` as SUSPECT legacy evidence, and the benchmark
  forbids test edits.

## Verification status

The FVK proof is constructed, not machine-checked. No tests, Python code,
`kompile`, `kast`, or `kprove` commands were run. The exact future
machine-check commands are recorded in `fvk/SPEC.md`, `fvk/PROOF.md`, and
`fvk/ITERATION_GUIDANCE.md`.
