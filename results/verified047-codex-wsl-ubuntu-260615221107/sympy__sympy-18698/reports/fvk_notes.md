# FVK Notes

## Decision

V1 stands unchanged. The FVK audit did not surface a source defect that is both
required by public intent and unaddressed by the V1 patch.

## Decisions Traced To Findings And Proof Obligations

1. Keep `_combine_factors()` as the mechanism for the reported bug.

   Trace: `fvk/FINDINGS.md` F-001 and `fvk/PROOF_OBLIGATIONS.md` PO-1 show that
   the reported univariate failure is exactly a missing "one factor per
   multiplicity" postcondition. PO-2 requires grouping after `Poly`
   normalization, which is where V1 placed the helper.

2. Keep the grouping limited to `method == 'sqf'`.

   Trace: PO-3 says ordinary `factor_list()` must preserve irreducible-factor
   output. The V1 condition `method == 'sqf'` satisfies that frame condition.

3. Keep the existing `polys` and `frac` output paths.

   Trace: PO-4 and PO-5 require output-shape preservation. V1 groups before the
   existing `polys` conversion branch and groups numerator/denominator lists
   independently, so no additional code change is justified.

4. Keep constants and empty factor lists unchanged.

   Trace: PO-6 and F-002 classify constant/error behavior as not required by the
   issue. V1 does not change `sqf_list(1)` behavior.

5. Do not broaden V1 into a no-generator multivariate behavior change.

   Trace: F-002 records the public evidence as underspecified: the issue says
   square-free helpers are univariate and multivariate behavior may be
   indeterminate, but it does not mandate a specific replacement behavior. PO-7
   therefore blocks using either legacy behavior or a new `ValueError` rule as a
   proven intent requirement in this pass.

6. Treat the SO `sqf(v.expand())` example as domain/documentation evidence for
   this patch, not as a complete multivariate algorithm requirement.

   Trace: F-003 connects that example to the public hint that square-free methods
   are intended for univariate polynomials. V1 already amends the relevant public
   helper docstrings; F-003 does not justify additional source behavior changes.

7. Preserve V1 despite the proof caveat.

   Trace: F-004 states that the constructed K model is intentionally abstract and
   not a full SymPy semantics. That caveat limits what the proof claims, but it
   does not identify a code bug in V1. The proof obligations are scoped to the
   changed property and are sufficient to justify keeping V1 for this task.

## Artifacts Added

The FVK phase added the requested artifacts:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

It also added supporting FVK adequacy and constructed-formal artifacts:

- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`
- `fvk/mini-sqf.k`
- `fvk/sqf-list-spec.k`

## Commands Not Run

Per task constraints, I did not run tests, Python, `kompile`, `kast`, or
`kprove`. The formal-tool commands are recorded in the FVK artifacts only.
