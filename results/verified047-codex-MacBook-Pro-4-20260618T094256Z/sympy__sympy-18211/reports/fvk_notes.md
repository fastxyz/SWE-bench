# FVK Notes

## Decision

V1 stands unchanged. I did not edit source files during the FVK pass.

## Artifact Trace

- `fvk/INTENT_SPEC.md` records the public obligation: a univariate relational
  whose solver cannot produce an exact set should be represented as
  `ConditionSet(symbol, relational, S.Reals)` by `as_set()`.
- `fvk/PUBLIC_EVIDENCE_LEDGER.md` entries E1-E3 trace that obligation to the
  issue text and expected output, while E7 records the regression frame for
  already-solved relationals.
- `fvk/relational-as-set-spec.k` contains four reachability claims:
  exact relational conversion, unsolved relational conversion, exact public
  non-periodic `as_set()` routing, and unsolved public non-periodic `as_set()`
  routing.
- `fvk/PROOF.md` constructs the proof that V1 returns exact solver results
  unchanged and converts solver `NotImplementedError` into the required real
  `ConditionSet`.
- `fvk/SPEC_AUDIT.md` marks the formal English obligations as matching the
  public intent.
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md` found no signature change, no new virtual
  dispatch argument, and no unhandled public callsite or override.
- `fvk/FINDINGS.md` records three findings: the original bug fixed by V1, the
  solved-relational regression frame, and the absence of proof-derived
  counterexamples requiring source edits.

## Why No Source Edit Was Applied

The only concrete bug finding is F1 in `fvk/FINDINGS.md`, and V1 already
addresses it by catching `NotImplementedError` in
`Relational._eval_as_set()` and returning `ConditionSet(x, self, S.Reals)`.

The regression-prevention finding F2 argues that exact solver results remain
unchanged because V1 returns directly from the `try` block when
`solve_univariate_inequality` succeeds. Any broader edit, such as changing
`solve_univariate_inequality` itself, catching broader exception classes, or
rewriting periodic/multivariate handling, would not trace to a concrete FVK
counterexample and would add regression surface.

The FVK proof is constructed, not machine-checked. Per the task constraints, I
did not run K tooling, tests, Python, or SymPy. The exact commands needed for a
future K check are listed in `fvk/PROOF.md`.
