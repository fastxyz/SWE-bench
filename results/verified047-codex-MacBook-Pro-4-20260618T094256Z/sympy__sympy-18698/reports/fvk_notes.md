# FVK Notes

## Decision

V1 stands unchanged. The FVK audit did not produce a concrete counterexample or
an unmet proof obligation that V1 demonstrably fails, so the revision discipline
does not permit a source edit.

## Trace to FVK Artifacts

`fvk/INTENT_SPEC.md` fixes the public intent as same-multiplicity grouping for
the expression-level square-free factor list, with ordinary `factor_list()`,
mixed-generator compatibility behavior, coefficients, sorting, fractions, and
output conversion framed as unchanged.

`fvk/sqf-combine-spec.k` encodes the audited behavior:

- Claim 1 covers the reported bug shape: two same-generator multiplicity-3
  factors become one product factor.
- Claim 2 confirms the grouping rule is exponent-general, not hard-coded to
  multiplicity `3`.
- Claim 3 preserves different-generator factors as separate entries, matching
  the compatibility frame from the in-repo `sqf_list(x*(x + y))` source test and
  the issue's ambiguity around multiple generators.
- Claim 4 proves the V1 dispatch leaves `method == 'factor'` unchanged.
- Claim 5 proves `method == 'sqf'` routes through the combiner.

`fvk/FINDINGS.md` records the audit outcome:

- Findings 1 and 2 confirm V1 discharges the reported square-free grouping
  problem in the constructed model.
- Finding 3 confirms ordinary `factor_list()` is not implicated.
- Finding 4 rejects broad all-generator combining as unsafe under the
  no-regression rule because public intent does not prove that edit
  regression-free.
- Finding 5 records the arbitrary-list/full-polynomial proof as an escalation
  boundary rather than a V1 counterexample.

`fvk/PUBLIC_COMPATIBILITY_AUDIT.md` found no changed public signature, return
shape, or override protocol. The only intended public behavior change is that
`sqf_list()` combines same-generator same-multiplicity square-free factors.

## No Source Edits

No source edits were made after V1. The only named alternative was broader
combination across different generator tuples. The FVK artifacts reject that
alternative for this pass because it touches a known mixed-generator public
scenario and lacks public-intent evidence strong enough to prove it
regression-free.

## Verification Status

The FVK proof is constructed, not machine-checked. Per the task constraint, no
tests, Python code, `kompile`, `kast`, or `kprove` commands were run. Exact
commands for later checking are recorded in `fvk/PROOF.md`.
