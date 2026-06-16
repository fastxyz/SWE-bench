# FVK Findings

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## F1: Pre-V1 `posify` dropped `finite=True`

Classification: code bug, resolved by V1.

Evidence: `SPEC.md` entries E1 and E2.

Input: `Symbol('x', finite=True)` with unknown positivity, passed to `posify`.

Observed pre-V1 behavior: replacement dummy was constructed as
`Dummy(s.name, positive=True)`, so the original `finite=True` assumption was not
passed to the dummy. The issue shows `print(xp.is_finite)` as `None`.

Expected behavior: the replacement dummy must retain `finite=True` while also
becoming positive.

Proof obligation link: PO2, PO3.

V1 status: resolved. V1 constructs the dummy from `s.assumptions0` and then sets
`positive=True`, so `finite=True` is part of the constructor arguments whenever
it was present on the original symbol.

## F2: Pre-V1 special-cased positivity instead of preserving the assumption family

Classification: code bug, resolved by V1.

Evidence: `SPEC.md` entries E3 and E4.

Input family: any symbol with `s.is_positive is None` and a known assumption fact
not implied by `positive=True`, for example `integer=True`, `rational=True`,
`even=True`, or `odd=True` when those facts are present and consistent with
positive narrowing.

Observed pre-V1 behavior: replacement dummies were built with only
`positive=True`, so unrelated known facts were omitted.

Expected behavior: the replacement operation should be a frame update over the
assumptions: retain every known non-`positive` fact and add `positive=True`.

Proof obligation link: PO2.

V1 status: resolved. V1 uses `assumptions0` as the source map and overwrites only
the `positive` entry.

## F3: Replacement must not force already-decided positivity cases through the positive branch

Classification: compatibility risk audited, no unresolved code bug found.

Evidence: `SPEC.md` entries E5, E7, and E8.

Input: a symbol whose `is_positive` is already `True` or `False`, including
publicly covered positive, negative, and noncommutative examples.

Observed candidate behavior: V1 leaves the existing guard
`if s.is_positive is None` unchanged.

Expected behavior: only unknown-positive symbols are replaced; known-positive
or known-not-positive symbols remain outside the dummy-construction branch.

Proof obligation link: PO1, PO6, PO7.

V1 status: confirmed. No source edit beyond V1 is justified by this finding.

## F4: Returned substitution map must still restore the original expression

Classification: compatibility risk audited, no unresolved code bug found.

Evidence: `SPEC.md` entries E6 and E7.

Input: an expression or iterable containing one or more replaceable symbols.

Observed candidate behavior: V1 only changes the constructor arguments for each
replacement dummy; it does not change the `reps` direction, final reverse map,
or iterable mapping logic.

Expected behavior: substituting the returned mapping into the transformed result
restores the original symbols.

Proof obligation link: PO4, PO5, PO7.

V1 status: confirmed. No source edit beyond V1 is justified by this finding.

## F5: Proof is constructed but not machine-checked

Classification: proof capability gap, not a code bug.

Evidence: benchmark instruction forbids running K tooling; FVK honesty gate
requires explicit labeling.

Input: the K artifacts in `mini-posify.k` and `posify-spec.k`.

Observed status: the proof is written as a constructed reachability argument, but
`kompile`, `kast`, and `kprove` were not run.

Expected next validation outside this benchmark: run the commands recorded in
`PROOF.md` and require `kprove` to return `#Top` before treating the proof as
machine-checked or removing tests as redundant.

Proof obligation link: PO8.

V1 status: no source edit required.
