# FVK Proof Obligations

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## PO1: Replacement Trigger

Statement: `posify` replaces a symbol with a positive dummy if and only if that
symbol's positivity is unknown, represented in code by `s.is_positive is None`.

Evidence: `SPEC.md` E4, E5, E7, E8.

Code locus: `repo/sympy/simplify/simplify.py`, the guard in the loop over
`eq.free_symbols`.

Discharge argument: V1 did not change the guard. The replacement branch is still
entered only under `if s.is_positive is None`.

Findings linked: F3.

Status: discharged by static inspection.

## PO2: Preservation of Non-Positive Assumptions

Statement: for every replaced symbol `s`, and every key/value pair
`k -> v` in `s.assumptions0` with `k != 'positive'`, the replacement dummy is
constructed with `k -> v`.

Evidence: `SPEC.md` E1, E2, E3, E4, E9.

Code locus: V1 assigns `assumptions = s.assumptions0`, then passes
`**assumptions` to `Dummy`.

Discharge argument: `assumptions0` is a new dict containing all non-`None`
assumption facts from the original symbol. V1 mutates that dict only at key
`positive`, so all other entries remain present when `Dummy` is called.

Findings linked: F1, F2.

Status: discharged by static inspection.

## PO3: Positive Narrowing

Statement: every replacement dummy is constructed with `positive=True`.

Evidence: `SPEC.md` E4, E5.

Code locus: V1 sets `assumptions['positive'] = True` immediately before the
`Dummy(s.name, **assumptions)` call.

Discharge argument: the constructor receives a keyword dictionary that includes
`positive=True` on every replacement-branch path.

Findings linked: F1, F2.

Status: discharged by static inspection.

## PO4: Same-Name Dummy and Reverse Restoration Map

Statement: every replacement dummy has the original symbol's name, and the
returned replacement map maps that dummy back to the original symbol.

Evidence: `SPEC.md` E5, E6, E7.

Code locus: V1 keeps `Dummy(s.name, **assumptions)` and the final return
`{r: s for s, r in reps.items()}`.

Discharge argument: V1 did not alter either the name argument or the map
inversion.

Findings linked: F4.

Status: discharged by static inspection.

## PO5: Iterable Coherence

Statement: iterable inputs use a consistent replacement for each symbol across
all iterable elements and return a reverse map from replacement to original.

Evidence: `SPEC.md` E6, E7.

Code locus: the iterable branch recursively calls `posify(s)` once per symbol,
stores a symbol-to-replacement map in `reps`, applies it to each element, and
returns the reverse map.

Discharge argument: V1 changes only the per-symbol dummy constructor arguments.
The iterable branch's recursion and substitution shape are unchanged, so it
inherits PO1-PO4 for each symbol and preserves the existing coherence behavior.

Findings linked: F4.

Status: discharged by static inspection.

## PO6: Consistency of Positive Narrowing

Statement: V1 must not add `positive=True` to symbols whose assumptions already
determine that positive narrowing is invalid.

Evidence: `SPEC.md` E4, E5, E8.

Code locus: the unchanged `s.is_positive is None` guard.

Discharge argument: if SymPy's assumption engine determines `s.is_positive` as
`True` or `False`, the replacement branch is skipped. For an unknown-positive
symbol, adding positivity is the intended narrowing operation described by
`posify`.

Findings linked: F3.

Status: discharged relative to SymPy's old-assumptions eligibility check.

## PO7: Public API and Return-Shape Compatibility

Statement: the patch must not change `posify`'s signature, arity, tuple return
shape, or caller-facing replacement-map direction.

Evidence: `SPEC.md` E6, E7.

Code locus: function signature and final return statements in
`repo/sympy/simplify/simplify.py`.

Discharge argument: V1 only changes how each replacement dummy's assumption
keywords are assembled. It does not alter `posify(eq)`, tuple arity, or return
map direction.

Findings linked: F3, F4.

Status: discharged by static inspection.

## PO8: FVK Honesty Gate

Statement: the proof must be labeled constructed, not machine-checked, and test
removal must not be recommended without conditioning it on later K execution.

Evidence: FVK `verify.md` honesty gate and benchmark instruction forbidding K
tooling.

Discharge argument: all FVK artifacts are labeled constructed, not
machine-checked. `PROOF.md` records commands but states they were not run.

Findings linked: F5.

Status: discharged.
