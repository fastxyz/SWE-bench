# FVK Notes

## Decision

V1 stands unchanged. The FVK audit found no additional production-code edit justified by the public intent and proof obligations.

## Trace To Findings And Obligations

Finding F1 identifies the real code bug: with `max_post_process_passes = 0`, the pre-V1 loop skipped the only assignment to `substitutions`, and the final branch raised `UnboundLocalError`. Proof obligations PO1 and PO2 cover the required fix. V1 discharges both by assigning `substitutions = False` before the repeated-pass loop in `repo/django/contrib/staticfiles/storage.py`.

Finding F2 covers the main rejected alternative: skipping all processing when `max_post_process_passes == 0`. PO5 requires preserving the initial post-processing pass because the source docstring and comments describe it as separate from the repeated stabilization loop. No source change was made for this alternative.

Finding F3 checks whether V1 accidentally changes positive-pass behavior. PO3 and PO4 show it does not: for `max_post_process_passes > 0`, the loop still resets `substitutions = False` at the start of each iteration and keeps the existing OR/break/max-exceeded logic. No refactor was made.

Finding F4 checks public compatibility. PO6 shows the V1 diff changes no signature, yielded tuple shape, virtual dispatch call, subclass contract, manifest format, or `collectstatic` consumer behavior. No compatibility edit was needed.

Finding F5 records the proof limitation. The K files and proof commands were written, but the task forbids running K tooling. This does not require a code change, but it means no test-removal recommendation is made.

## Artifacts Written

The FVK audit produced:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`
- `fvk/mini-staticfiles.k`
- `fvk/staticfiles-spec.k`

## Execution Policy

No tests, Python code, or K tooling were run. The commands required for a later machine check are recorded in `fvk/PROOF.md` and `fvk/ITERATION_GUIDANCE.md`.
