# FVK Notes

## Decision

V1 stands unchanged. The FVK audit did not justify any additional production
source edit.

## Trace to findings and proof obligations

- Kept the class-MRO lookup change because Finding F1 and PO1 show that the
  reported `Foo`/`Bar` case now includes both marker names. This is the core
  public issue obligation.
- Kept `store_mark(... consider_mro=False)` because Finding F2 and PO2 show that
  storing the MRO-expanded view would duplicate inherited marks once collection
  later walks the MRO. PO3 also depends on this direct-only storage to avoid base
  or sibling mutation.
- Kept the non-class path unchanged because PO4 discharges the frame condition
  for functions/modules and the task scope is class MRO lookup.
- Kept invalid mark handling unchanged because PO5 shows all paths still call
  `normalize_mark_list`.
- Did not alter marker order because Finding F3 and PO6 classify sibling-base
  order as under-specified by public intent. The issue requires both markers; it
  does not give an order-sensitive assertion. Changing V1 to a different order
  policy would be a broader behavioral decision without enough public evidence.
- Did not add metaclass descriptor support because Finding F4 keeps that behavior
  outside the proved domain. The issue presents the metaclass as a workaround for
  missing MRO merging, not as a public API requirement pytest must preserve.
- Accepted the helper signature change because PO7 and
  `fvk/PUBLIC_COMPATIBILITY_AUDIT.md` show existing callsites remain valid: the
  new parameter is keyword-only and defaults to the original public call shape.

## Artifacts

The FVK package is under `fvk/`:

- Required task artifacts: `SPEC.md`, `FINDINGS.md`, `PROOF_OBLIGATIONS.md`,
  `PROOF.md`, `ITERATION_GUIDANCE.md`.
- Formal/adequacy support: `mini-python-marks.k`, `mark-mro-spec.k`,
  `INTENT_SPEC.md`, `PUBLIC_EVIDENCE_LEDGER.md`, `FORMAL_SPEC_ENGLISH.md`,
  `SPEC_AUDIT.md`, `PUBLIC_COMPATIBILITY_AUDIT.md`.

No tests, Python code, or K tooling were run.
