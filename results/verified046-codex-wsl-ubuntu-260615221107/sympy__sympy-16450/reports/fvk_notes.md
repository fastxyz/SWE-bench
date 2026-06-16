# FVK Notes

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Decision

V1 stands unchanged.

The audit found no new source edit justified by the FVK artifacts. The issue's
public intent is that `posify` should add `positive=True` only when positivity is
unknown while retaining the original symbol's other assumptions. V1 implements
that directly.

## Traceability

F1 identifies the reported bug: `finite=True` was dropped because pre-V1 called
`Dummy(s.name, positive=True)`. PO2 and PO3 are discharged by V1 because it
copies `s.assumptions0`, sets `positive=True`, and passes the merged assumptions
to `Dummy`.

F2 generalizes the bug to the assumption family named in the issue and hint.
PO2 is the governing obligation: every non-`positive` fact in `assumptions0`
must be passed to the replacement dummy. V1 satisfies this without special cases,
so I did not narrow the fix to `finite=True`.

F3 checks whether V1 might incorrectly replace symbols whose positivity is
already known. PO1 and PO6 are discharged because the existing
`s.is_positive is None` guard is unchanged. I kept that guard unchanged.

F4 checks restoration and iterable behavior. PO4, PO5, and PO7 are discharged
because V1 does not alter dummy naming, map reversal, tuple return shape, or the
iterable branch. I made no edits in those areas.

F5 is the honesty finding required by the benchmark and FVK method. PO8 is
discharged by labeling the artifacts constructed, not machine-checked, and by
recording K commands without running them.

## Files Added

`fvk/SPEC.md`: intent ledger, formal contract, adequacy check, and compatibility
audit.

`fvk/FINDINGS.md`: resolved pre-V1 bugs, compatibility checks, and proof-honesty
finding.

`fvk/PROOF_OBLIGATIONS.md`: explicit obligations PO1-PO8 and their discharge
status.

`fvk/PROOF.md`: constructed proof, verification conditions, residual risk, and
commands to run later.

`fvk/ITERATION_GUIDANCE.md`: conclusion that V1 stands, rejected alternatives,
and recommended follow-up tests.

`fvk/mini-posify.k` and `fvk/posify-spec.k`: compact Mini-SymPy K artifacts for
the assumption-preservation core.

No source files were changed during the FVK pass.
