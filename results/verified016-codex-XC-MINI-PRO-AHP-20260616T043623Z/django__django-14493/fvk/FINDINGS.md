# FVK Findings

Status: constructed, not machine-checked. No tests, Python, or K tooling were run.

## F1: Pre-V1 Unbound Local On Zero Passes

Classification: code bug, resolved by V1.

Evidence: SPEC ledger I1, I3, and I4.

Concrete input: a `ManifestStaticFilesStorage` subclass with `max_post_process_passes = 0`, invoked through `collectstatic`.

Observed before V1: the repeated-pass loop was skipped, `substitutions` had no local binding, and the final `if substitutions:` raised `UnboundLocalError`.

Expected: zero repeated passes should be allowed and should not crash at the final branch condition.

V1 status: resolved by `repo/django/contrib/staticfiles/storage.py`, where `substitutions = False` is assigned before the repeated-pass loop. This discharges PO1 and PO2.

## F2: Zero Passes Must Not Be Reinterpreted As "Skip All Processing"

Classification: rejected alternative, no code change.

Evidence: SPEC ledger I5, I6, and I8.

Concrete input: any `paths` mapping with `max_post_process_passes = 0`.

Observed candidate alternative: skipping the initial pass would avoid the unbound local but would also bypass the documented hash/copy and adjustable-file collection work.

Expected: only the repeated stabilization passes are suppressed by a zero pass count; the initial pass remains intact.

V1 status: no change needed. V1 leaves the initial pass unchanged and changes only the binding state of `substitutions` before the repeated-pass loop. This is covered by PO5.

## F3: Positive-Pass Behavior Preservation

Classification: proof-derived compatibility check, no code change.

Evidence: SPEC ledger I5 and I6; proof obligation PO3.

Concrete input: `max_post_process_passes > 0` with any finite sequence of `_post_process()` substitution flags.

Observed in V1: the pre-loop initializer is overwritten by `substitutions = False` at the start of the first loop iteration. The inner OR and break logic are unchanged.

Expected: positive-pass behavior remains identical to the pre-V1 algorithm.

V1 status: confirmed by inspection and formal obligation PO3. No further source edit is justified.

## F4: Public API And Consumer Protocol Are Preserved

Classification: compatibility check, no code change.

Evidence: SPEC ledger I7; proof obligation PO6.

Concrete input: `collectstatic` iterating over `self.storage.post_process(found_files, dry_run=...)`.

Observed in V1: method signature, yielded triple shape, exception-as-processed-result convention, and manifest update flow are unchanged.

Expected: `collectstatic` continues to consume the same generator protocol.

V1 status: confirmed. No public compatibility repair is needed.

## F5: Proof Is Constructed, Not Machine-Checked

Classification: proof capability gap, not a code bug.

Evidence: task instruction forbids running K tooling; FVK honesty gate requires labeling the proof as constructed.

Concrete input: all claims in `fvk/staticfiles-spec.k`.

Observed: the K artifacts and commands are written, but `kompile`, `kast`, and `kprove` were not run.

Expected: test removal and machine-verified confidence must be conditioned on a later `kprove` run returning `#Top`.

V1 status: no code change. Keep or add regression coverage; do not remove tests based on this constructed proof alone.

## Summary Verdict

The FVK audit found no unresolved production-code issue in V1. The only code bug identified by the public intent, F1, is discharged by the existing one-line initializer. V1 stands unchanged.
