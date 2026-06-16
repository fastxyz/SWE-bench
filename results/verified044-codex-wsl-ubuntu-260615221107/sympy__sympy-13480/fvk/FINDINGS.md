# FVK Findings

Status: constructed, not machine-checked.

## F1 - Unbound local read in `coth.eval` additive branch

Classification: code bug, resolved by V1.

Evidence: the public issue traceback points to `if cotm is S.ComplexInfinity`
and reports `NameError: name 'cotm' is not defined`. The same issue includes
the public hint that `cotm` should be `cothm`.

Input family: any `coth.eval` call that reaches the additive-period branch with
`m` truthy after `_peeloff_ipi(arg)`, including the reported
`coth(log(tan(x))).subs(x, n)` values that expose this path.

Observed before V1: the branch attempted to read unbound `cotm` and raised
`NameError`.

Expected: the branch must test the computed `cothm = coth(m)` value and then
return `coth(x)` or `tanh(x)` according to that value.

Resolution: V1 changed `cotm` to `cothm` in
`repo/sympy/functions/elementary/hyperbolic.py`. This discharges PO1, PO2, and
PO3 for the focused branch.

## F2 - No evidence for broader code changes

Classification: no code bug found in the audited scope.

Evidence: the public problem identifies a single undefined-name failure, the
public hint names the exact replacement, and the neighboring `tanh` and `cot`
periodic branches use the same "compute local, test same local" structure.

Decision: keep V1 unchanged beyond the typo fix. There is no public-intent
evidence in the allowed inputs requiring a different return formula, API change,
or unrelated `coth.eval` refactor.

Related obligations: PO4 and PO5.

## F3 - Proof not machine-checked in this environment

Classification: proof capability and environment constraint, not a code bug.

Evidence: the user explicitly forbids running tests, Python, `kompile`, or
`kprove`.

Consequence: the proof artifacts are constructed and include exact commands,
but no claim is represented as machine-checked. Test removal is not recommended.

Related obligations: all proof obligations remain constructed-only until the
K commands in `PROOF.md` are run in a suitable environment.
