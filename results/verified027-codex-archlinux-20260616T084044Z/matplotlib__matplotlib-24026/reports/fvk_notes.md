# FVK Notes

## Decision Summary

V1 stands unchanged. The FVK audit found that the V1 source change discharges
the explicit-`colors` obligations that follow from the public issue, and it did
not surface an intent-backed reason to further edit `repo/lib/matplotlib/stackplot.py`.

No tests, Python, or K tooling were run.

## Decisions Traced to Findings and Proof Obligations

1. Keep the local explicit color cycle from V1.

   Findings: F1 and F2 identify the original defects: explicit colors were
   routed through `axes.set_prop_cycle`, which both rejected `C<N>` aliases and
   replaced the Axes property cycle.

   Proof obligations: PO1 requires branch-local color handling, PO2 requires
   cyclic layer facecolors, PO3 requires avoiding prop-cycle validation for
   `C<N>` aliases, and PO4 requires preserving the Axes cycler on the explicit
   path.

   Decision: V1 satisfies these obligations by using `itertools.cycle(colors)`
   when `colors is not None` and by passing each selected value directly to
   `fill_between(facecolor=...)`.

2. Do not change the `colors is None` path.

   Finding: F3 records the only broader ambiguity: the issue title could be
   read as "never advance the Axes cycler", but the docstring says omitted
   colors come from the Axes property cycle and the reproducer uses explicit
   `colors=`.

   Proof obligation: PO5 intentionally preserves legacy default behavior,
   where `axes._get_lines.get_next_color()` is called once per layer.

   Decision: no source edit. Making the default path snapshot the cycle would
   be a compatibility change not justified by the public issue.

3. Do not add an empty-`colors` guard.

   Finding: F4 marks empty explicit color sequences as outside the proved
   domain. The issue and docstring require a sequence that can supply colors;
   they do not specify `colors=[]`.

   Proof obligations: D2 and PO1 require a finite non-empty explicit color
   sequence.

   Decision: no source edit. A clearer `ValueError` for `colors=[]` may be a
   future cleanup, but it is not required for this bug.

4. Preserve public API and non-color behavior.

   Findings: F5 confirms no public signature or dispatch shape changed; F6
   records numeric stacking and baseline calculations as framed behavior.

   Proof obligations: PO6 requires public compatibility, and PO7 requires
   preserving non-color stackplot behavior.

   Decision: no source edit beyond V1. The patch remains limited to color
   source selection.

5. Keep tests untouched.

   Findings: F1-F3 imply useful future test coverage for explicit `C<N>`
   aliases, cycle preservation on explicit colors, repeated explicit colors,
   and unchanged default behavior.

   Proof obligations: PO1-PO5 cover those behaviors in the constructed proof.

   Decision: no test files were modified because the benchmark forbids it.

## Artifacts

The FVK package is under `fvk/`:

- `SPEC.md`
- `FINDINGS.md`
- `PROOF_OBLIGATIONS.md`
- `PROOF.md`
- `ITERATION_GUIDANCE.md`
- `mini-stackplot.k`
- `stackplot-spec.k`

The proof is constructed, not machine-checked. `fvk/PROOF.md` records the
commands that would be run in a K-enabled environment.
