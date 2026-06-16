# FVK Notes

## Method

I read the required FVK documents and the bootstrap primers they reference. No tests, Python, or K tooling were run. Commands that FVK would normally run are recorded in `fvk/PROOF.md` only.

## Decisions and Traceability

### Kept V1's total-degree filter

Decision: keep `sum(powers.values()) >= min_degree` in both integer-mode candidate filters.

Reason: `fvk/FINDINGS.md` F1 identifies the original bug: the old `max(powers.values())` predicate checked only the largest single-variable exponent and rejected mixed monomials such as exponent counts `[1, 2, 0]` at `min_degree = 3`. `fvk/PROOF_OBLIGATIONS.md` PO-4 and PO-5 require lower-bound exactness in the commutative and non-commutative branches, and PO-6 gives the concrete counterexample showing the legacy predicate cannot satisfy public intent.

### Added a V2 boundary fix for empty variables

Decision: change the early unit-monomial branch so `S.One` is yielded only when `min_degree == 0`.

Reason: `fvk/FINDINGS.md` F2 surfaced a V1 gap: `itermonomials([], 2, 1)` would yield `1`, but the total-degree contract allows only monomials whose total degree is at least `1`; `1` has total degree `0`. `fvk/PROOF_OBLIGATIONS.md` PO-2 requires the unit monomial boundary to respect the lower bound. The new guard discharges PO-2.

### Left list-valued degree mode unchanged

Decision: do not edit the list-valued `max_degrees` / `min_degrees` branch.

Reason: public intent gives list mode separate per-variable semantics, not total-degree semantics. `fvk/PROOF_OBLIGATIONS.md` PO-7 is a frame obligation for that branch, and the diff remains confined to the integer total-degree path.

### Left public API and callsites unchanged

Decision: do not change the function signature or non-test callsites.

Reason: `fvk/FINDINGS.md` F5 and `fvk/PROOF_OBLIGATIONS.md` PO-8 show there is no compatibility blocker: the signature remains the same, the function remains a generator, and non-test source callsites use the default `min_degrees=None` behavior.

### Did not modify tests

Decision: no test files were edited.

Reason: the task forbids modifying tests. `fvk/FINDINGS.md` F3 records the relevant test gaps and `fvk/ITERATION_GUIDANCE.md` lists recommended tests for maintainers.

### Recorded proof limitations instead of overstating verification

Decision: include K artifacts and a constructed proof, but label them not machine-checked.

Reason: `fvk/FINDINGS.md` F4 records that the mini-K model preserves the total-degree filter property but abstracts full Python generator mechanics and SymPy expression canonicalization. This limitation does not block the source fix, but it does block claims of end-to-end machine verification or test deletion.
