# Proof Obligations

Status: constructed, not machine-checked.

## PO1: adequacy of the intended contract

The formal claims must say that marker skips point to the item location and
that `--runxfail` does not affect this. They must not encode the pre-fix
`src/_pytest/skipping.py` location as intended behavior.

Discharged by: `INTENT_SPEC.md`, `PUBLIC_EVIDENCE_LEDGER.md`, `SPEC_AUDIT.md`,
and K claim C1.

## PO2: reachability of marker-skip rewrite under runxfail

For a setup skipped report with `runxfail=True`,
`skipped_by_mark_key=True`, `outcome=="skipped"`, and tuple-like skip
`longrepr`, `pytest_runtest_makereport` reaches the marker-skip rewrite and
sets the location to `item.reportinfo()`.

Discharged by: V1 branch order, K claim C1, and proof step P2.

## PO3: xfail-specific rewrites remain disabled under runxfail

When `runxfail=True`, the xfail-exception and evaluated-xfail branches must not
set `wasxfail` or override outcomes.

Discharged by: the `not item.config.option.runxfail` guards in V1 and K claim
C3.

## PO4: non-runxfail xfail behavior is preserved

When `runxfail=False`, V1's added guard is logically true, so the
xfail-exception and evaluated-xfail branches remain reachable exactly as in the
pre-V1 hook.

Discharged by: syntactic equivalence of branch predicates under
`runxfail=False` and K claim C4 for the xfail-exception branch.

## PO5: non-marker skips are not broadened into marker skips

The item-location rewrite remains gated by `skipped_by_mark_key` and skipped
tuple reports. Runtime skips with the marker flag false are not rewritten by
the marker-skip branch.

Discharged by: unchanged `skipped_by_mark_key` condition and K claim C2.

## PO6: public compatibility is preserved

No public hook signature, option name, report attribute, or store key changes.

Discharged by: `PUBLIC_COMPATIBILITY_AUDIT.md`.

## PO7: proof honesty

The proof must be labeled constructed, not machine-checked, because this task
forbids `kompile` and `kprove`.

Discharged by: labels and commands in `SPEC.md`, `PROOF.md`, and
`ITERATION_GUIDANCE.md`.
