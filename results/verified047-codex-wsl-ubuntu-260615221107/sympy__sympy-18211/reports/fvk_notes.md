# FVK Notes

## Decision

V1 stands unchanged. The FVK audit found no source-level problem beyond the
bug V1 already fixed.

## Trace to Findings and Proof Obligations

Finding F1 identifies the original bug: an in-domain univariate relational
`as_set()` call could surface `NotImplementedError` from
`solve_univariate_inequality`. Proof obligations PO1, PO3, and PO4 show that V1
handles the audited domain, catches that exact solver incompleteness signal, and
returns a well-formed `ConditionSet(x, self, S.Reals)`. This justifies keeping
the V1 fallback.

Finding F2 records the solved-case frame condition. PO2 shows that when the
solver returns normally, V1 returns that solver result directly. This justifies
not adding extra wrapping or post-processing around solved results.

Finding F3 records compatibility with direct solver callers. PO5 and PO6 show
that V1 catches only `NotImplementedError`, leaves other exception behavior
alone, and does not change the solver API. This justifies not editing
`solve_univariate_inequality`.

Finding F4 records a residual non-goal for periodic relational `as_set()`
behavior. PO1 limits the proof to the existing univariate, non-periodic
relational path that the issue and public hint target. This justifies not
expanding the patch to periodic or multivariate behavior in this task.

## Artifacts Created

Created the required FVK artifacts:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

Also created the formal core required by the FVK documentation:

- `fvk/mini-sympy-as-set.k`
- `fvk/relational-as-set-spec.k`

## Execution Constraints

No tests, Python commands, `kompile`, `kast`, or `kprove` were run. The K proof
is constructed, not machine-checked. The commands to run later are recorded in
the FVK artifacts.
