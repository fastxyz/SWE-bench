# FVK Notes

## Decision

V1 stands unchanged. The FVK audit found that the existing source edit in
`repo/lib/matplotlib/ticker.py` is the targeted change needed for the public
issue, and no additional source edit is justified by the proof obligations.

## Trace to Findings and Proof Obligations

`fvk/FINDINGS.md` F1 identifies the original defect as loss of reversed order
for finite positive log limits. `fvk/PROOF_OBLIGATIONS.md` PO1 proves the V1
mechanism: `LogLocator.nonsingular(HIGH, LOW)` with `HIGH > LOW > 0` records
the swap, performs the existing checks on sorted values, and returns
`(HIGH, LOW)`.

F1 and PO2 show why this is sufficient at the user-visible axis level:
`Axes.set_ylim` / `Axes.set_xlim` store the locator's returned pair in the view
interval, and `Axis.get_inverted()` is true exactly when the stored interval is
reversed.

PO3 confirms that no additional edit is needed in `repo/lib/matplotlib/scale.py`
because `LogScale.limit_range_for_scale` is an identity for positive bounds and
does not reorder them.

PO4 confirms V1 does not overcorrect normal positive limits: when the input is
already increasing, `swapped` is false and the increasing order is preserved.

F2 and PO5 justify keeping the invalid and singular branches unchanged.
Nonpositive explicit log-axis limits are handled before locator normalization,
and equal positive limits still need singular-interval expansion rather than
inversion semantics.

F3, PO6, and PO7 justify not changing tick generation or public call sites.
`LogLocator.tick_values` already sorts local variables for tick calculation,
and V1 did not change the `nonsingular` signature or tuple return shape.

## Formal Artifacts

The required FVK artifacts are present under `fvk/`:

- `SPEC.md`
- `FINDINGS.md`
- `PROOF_OBLIGATIONS.md`
- `PROOF.md`
- `ITERATION_GUIDANCE.md`

The FVK adequacy and formal-core files are also present:

- `INTENT_SPEC.md`
- `PUBLIC_EVIDENCE_LEDGER.md`
- `FORMAL_SPEC_ENGLISH.md`
- `SPEC_AUDIT.md`
- `PUBLIC_COMPATIBILITY_AUDIT.md`
- `mini-python-log-limits.k`
- `log-locator-spec.k`

No tests, Python, or K tooling were run, following the benchmark constraints.
