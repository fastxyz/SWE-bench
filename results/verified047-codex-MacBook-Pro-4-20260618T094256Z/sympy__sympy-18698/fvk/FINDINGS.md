# Findings

Status: constructed, not machine-checked.

## Finding 1: V1 Fixes the Reported Same-Generator Grouping Bug

Evidence: `sqf-combine-spec.k` claim 1 models the reported factor-list shape:
two factors with generator key `1` and multiplicity `3` become one product factor
with multiplicity `3`.

Example: before V1, the generic expression path could return `(x - 3, 3)` and
`(x - 2, 3)` separately. Expected per public intent: one factor
`(x**2 - 5*x + 6, 3)`. V1's `_combine_factors` multiplies same-key entries and
therefore discharges this finding in the constructed model.

Classification: confirmed fix, no source edit required.

## Finding 2: The Equal-Multiplicity Rule Is General, Not Exponent-Specific

Evidence: `sqf-combine-spec.k` claim 2 and claim 5 cover equal multiplicities
other than `3`. V1 uses one helper for all exponents, so the implementation is
not hard-coded to the issue's example.

Classification: confirmed fix, no source edit required.

## Finding 3: Ordinary `factor_list()` Is Not Regressed by V1

Evidence: `sqf-combine-spec.k` claim 4 models `method == factor` as a no-op for
the new normalizer. The code guard is `if method == 'sqf'`.

Classification: regression check passed in the constructed model, no source edit
required.

## Finding 4: Mixed-Generator Behavior Is a Deliberate Compatibility Frame

Evidence: `sqf-combine-spec.k` claim 3 preserves separate entries when generator
keys differ. `PUBLIC_COMPATIBILITY_AUDIT.md` links this to the in-repo public
test for `sqf_list(x*(x + y))` and the issue discussion's ambiguity around
multiple generators.

Alternative considered: combine all equal exponents regardless of generator
tuple. Rejected for this revision because it would touch a known mixed-generator
scenario without public intent strong enough to prove the edit regression-free.

Classification: V1 stands; no source edit required.

## Finding 5: Full Arbitrary-List Proof Is Escalation-Bounded

Evidence: `sqf-combine-obligations.k` states the arbitrary finite-list grouping
theorem as `groupedByKey(FS, OUT)`. A full proof requires list induction and a
polynomial-product abstraction beyond the bundled mini model. This is a proof
capability boundary, not a discovered V1 counterexample.

Classification: proof capability gap / `[ESCALATION BOUNDARY]`. Keep tests;
do not claim machine-checked status until the emitted K commands return `#Top`
and the open obligation is discharged or intentionally scoped.

## Repair Decision

The FVK audit found no concrete counterexample and no unmet proof obligation
that V1 demonstrably fails. Under the revision discipline, V1 remains unchanged.
