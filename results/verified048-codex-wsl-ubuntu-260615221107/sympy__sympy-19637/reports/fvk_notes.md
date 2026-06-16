# FVK Notes

Status: V1 stands unchanged after the FVK audit. No tests, Python, or K tooling
were run.

## Decisions

Kept the V1 source change in `repo/sympy/core/sympify.py` unchanged. F-001
identifies the original bug as a no-placeholder parenthesized input reaching an
undefined `kern` read, and PO-2 proves the V1 branch shape prevents that read by
leaving `hit` false and returning before cleanup.

Did not initialize `kern` to a sentinel. F-002 and PO-3 show that the meaningful
invariant is stronger: `hit` should become true only after a real placeholder is
created. A sentinel would avoid the exception, but it would not express the
actual cleanup guard as directly as V1 does.

Did not alter the placeholder rewrite or cleanup behavior. F-002, PO-3, and
PO-5 confirm the documented anti-distribution examples still use the existing
placeholder path, with `kern` assigned before cleanup can read it.

Did not change `sympify` or expression semantics. F-003 and PO-7 mark those
behaviors as outside this local proof slice; the public issue is the internal
`UnboundLocalError`, not a parser or algebraic simplification defect.

Did not refactor the random fresh-name loop. F-004 and PO-7 record total
termination as an unproved boundary, but partial correctness is enough for this
issue and the broader deterministic-fresh-name change is not justified by the
public report.

Did not change public API or callsites. F-005 and PO-6 confirm V1 preserves the
one-argument `kernS(s)` interface and changes only internal bookkeeping.

## Artifacts

The FVK artifacts are in `fvk/`: `SPEC.md`, `FINDINGS.md`,
`PROOF_OBLIGATIONS.md`, `PROOF.md`, and `ITERATION_GUIDANCE.md`. I also added
the constructed K-style core files `mini-kernS.k` and `kernS-spec.k` because the
FVK documentation requires a formal core even when machine checking is not run.
