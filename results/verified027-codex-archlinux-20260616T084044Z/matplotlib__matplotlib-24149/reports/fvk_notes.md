# FVK Notes

## Decision

V1 stands unchanged. The FVK audit did not surface a source-code problem that
requires a V2 edit.

## Trace to Findings and Proof Obligations

The decision to keep the two `except StopIteration` branches in
`repo/lib/matplotlib/axes/_axes.py` is justified by FINDINGS F-001 and
PROOF_OBLIGATIONS PO-001/PO-002. The public issue identifies all-nonfinite x
data as in scope, and the proof obligation requires `_convert_dx` to recover
from `_safe_first_finite` having no finite representative. V1 satisfies that by
falling back to `cbook.safe_first_element` for both `x0` and `xconv`.

The decision not to broaden the fix to always use the first element is justified
by FINDINGS F-002 and PO-003. The public hint says the first-finite behavior
fixed a separate leading-NaN bug, so V1 must preserve `_safe_first_finite` when
it succeeds. Catching only `StopIteration` does that.

The decision not to change `ax.bar([], [])` behavior is justified by FINDINGS
F-003 and PO-004. Empty data is mentioned as context for seaborn's phantom-bar
workaround, but the requested repair is for NaN data. V1 leaves the
`xconv.size == 0` branch unchanged.

The decision not to change the outer conversion fallback is justified by PO-005.
The existing fallback for `ValueError`, `TypeError`, and `AttributeError`
remains intact; the new handling is limited to the representative-selection
`StopIteration` named by the issue.

The decision not to edit public API shape or global `cbook` behavior is
justified by FINDINGS F-005 and PO-007. `_convert_dx`'s signature and callers
are unchanged, and changing `cbook._safe_first_finite` globally would affect
unrelated callers that already treat `StopIteration` as meaningful.

The decision not to remove or edit tests is justified by FINDINGS F-004 and the
task constraints. The proof is constructed, not machine-checked, and this
benchmark explicitly fixes production code only.

## Artifacts Produced

The FVK artifacts are under `fvk/`. The required top-level artifacts are
`SPEC.md`, `FINDINGS.md`, `PROOF_OBLIGATIONS.md`, `PROOF.md`, and
`ITERATION_GUIDANCE.md`. I also wrote the adequacy and compatibility artifacts
required by the FVK method: `INTENT_SPEC.md`, `PUBLIC_EVIDENCE_LEDGER.md`,
`FORMAL_SPEC_ENGLISH.md`, `SPEC_AUDIT.md`, `PUBLIC_COMPATIBILITY_AUDIT.md`, and
the constructed K files `mini-convert-dx.k` and `convert-dx-spec.k`.

No tests, Python, or K tooling were run.
