# FVK Specification: django__django-14493

Status: constructed, not machine-checked. No tests, Python, or K tooling were run.

## Scope

The audited unit is `HashedFilesMixin.post_process()` in `repo/django/contrib/staticfiles/storage.py`, limited to the control-flow region affected by `max_post_process_passes` and the final `if substitutions:` check. The file-copying, hashing, URL conversion, and storage side effects of `_post_process()` are modeled abstractly as finite pass outcomes because the issue concerns control-flow definedness, not hash correctness.

## Intent Spec

For a `ManifestStaticFilesStorage` subclass with `max_post_process_passes = 0`, `collectstatic` must not crash with `UnboundLocalError` from reading `substitutions` after the repeated-pass loop is skipped.

The value `0` is in the intended domain for `max_post_process_passes` because the public reproduction sets that class attribute and asks for `collectstatic` to run without the reported crash.

`max_post_process_passes = 0` disables the repeated stabilization passes after the initial post-processing pass. It does not disable the documented initial pass that hashes/copies files and collects adjustable files.

For positive `max_post_process_passes`, the repeated-pass behavior must remain unchanged: each pass starts with `substitutions = False`, ORs together the `subst` flags from `_post_process()`, breaks when a pass makes no substitutions, and yields the existing "Max post-process passes exceeded" `RuntimeError` only when all allowed repeated passes still report substitutions.

The public API shape must remain unchanged: `post_process(paths, dry_run=False, **options)` remains a generator of `(original_path, processed_path, processed)` triples for `collectstatic`.

## Public Evidence Ledger

I1. Source: prompt. Quote: "ManifestStaticFilesStorage crashes with max_post_process_passes = 0." Obligation: boundary case `max_post_process_passes == 0` must not crash with the reported local-variable error. Status: encoded in PO1 and PO2.

I2. Source: prompt. Quote: "Derive a custom class from ManifestStaticFilesStorage and set max_post_process_passes to 0". Obligation: subclass-provided zero is an in-domain configuration, not an invalid input. Status: encoded in PO2.

I3. Source: prompt traceback. Quote: "if substitutions: UnboundLocalError: local variable 'substitutions' referenced before assignment". Obligation: the final branch condition must read a bound local on every in-domain path. Status: encoded in PO1.

I4. Source: prompt diagnosis. Quote: "subtitutions is only set if the loop is entered at least once." Obligation: a correct fix must give `substitutions` a value on the path where the repeated-pass loop has zero iterations. Status: encoded in PO1 and PO2.

I5. Source: source docstring, `storage.py`. Quote: "Processing is actually two separate operations: 1. renaming files ... 2. adjusting files..." Obligation: preserve the existing initial post-processing responsibilities; do not use the zero-pass bug fix to bypass all processing. Status: encoded in PO5.

I6. Source: source comment, `storage.py`. Quote: "Do a single pass first. Post-process all files once..." Obligation: the initial pass happens before the `max_post_process_passes` loop; the loop count controls only repeated passes. Status: encoded in PO5.

I7. Source: `collectstatic.py`. Quote: "for original_path, processed_path, processed in processor". Obligation: `collectstatic` expects `post_process()` to remain an iterable of result triples; the fix must not change this producer/consumer protocol. Status: encoded in PO6.

I8. Source: public hint. Quote: "An effective workaround is overriding patterns = (). It might not be worth fixing the UnboundLocalError. I think it's worth fixing." Obligation: the issue is specifically the `UnboundLocalError`; `patterns = ()` is a workaround, not the required semantic change. Status: used to reject the alternative "skip all processing when pass count is zero."

## Formal Spec English

Claim C1, zero-pass definedness: For any finite initial post-processing result and any storage state satisfying the normal `post_process()` preconditions, if `max_post_process_passes == 0`, then after the initial pass and path filtering, the repeated-pass loop executes zero iterations and the final `if substitutions:` reads `False`, not an unbound local.

Claim C2, zero-pass no max-exceeded result: Under the same conditions as C1, the method does not yield the synthetic `('All', None, RuntimeError('Max post-process passes exceeded.'))` result solely because the pass count is zero.

Claim C3, positive-pass preservation: For any `max_post_process_passes > 0`, the extra initializer before the loop is overwritten by the first statement inside each loop iteration, so the loop's observable behavior is the same as before V1.

Claim C4, max-exceeded exactness: For positive pass counts, the max-exceeded result is yielded exactly when every allowed repeated pass reports at least one substitution before the loop count is exhausted.

Claim C5, frame condition: The fix does not alter construction of `adjustable_paths`, `processed_adjustable_paths`, the initial `_post_process()` pass, the `hashed_files` update, or the final yield of processed adjustable paths.

Claim C6, compatibility: The fix does not alter method signatures, return shape, virtual dispatch arguments, storage manifest format, or `collectstatic` consumption.

## Spec Audit

C1 passes: it directly restates I1, I3, and I4.

C2 passes: it follows from I1 and I2; zero is valid and should not be treated as "max exceeded" before any repeated pass was requested.

C3 passes: it is implementation-derived but justified as a frame condition by I5, I6, and the task requirement for a minimal targeted fix.

C4 passes: it preserves the existing documented error path for positive repeated-pass exhaustion and is necessary to show V1 did not broaden the change.

C5 passes: it is a narrow source-level frame condition supported by I5 and I6.

C6 passes: it is supported by I7 and by the source diff, which changes only a local variable initializer.

## Public Compatibility Audit

Changed public symbol: none. The only source change is a local assignment inside `HashedFilesMixin.post_process()`.

Method signature: unchanged.

Generator item shape: unchanged.

Subclass compatibility: preserved. Subclasses that set `max_post_process_passes` to zero now exercise a defined path; subclasses with positive values continue to enter the same loop body.

Virtual dispatch compatibility: no call to a virtual method receives new arguments, and no override contract changes.

Storage/manifest compatibility: unchanged. `self.hashed_files.update(hashed_files)` and manifest saving remain outside the edited region.

## Domain and Assumptions

The formal domain is non-negative integer `max_post_process_passes` values. Negative values are not part of the public intent; the V1 initializer also makes them defined in practice, but that is outside the proof obligation.

The proof is partial correctness. It assumes `_post_process()` terminates for the finite `paths` input and yields finite per-pass substitution flags. Termination, filesystem behavior, and hash correctness are not proved.

The K model is an abstraction over the repeated-pass tail of `post_process()`. It preserves the property under verification: whether `substitutions` is bound, whether zero passes trigger the max-exceeded branch, and whether positive-pass loop behavior is preserved.
