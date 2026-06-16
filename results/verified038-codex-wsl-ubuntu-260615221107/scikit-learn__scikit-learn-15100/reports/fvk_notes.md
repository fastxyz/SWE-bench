# FVK Notes

## Decision: keep V1 source unchanged

V1 removes the `normalized == s` early return and always filters combining characters after NFKD normalization. That directly fixes F-001 and satisfies F-002. The decision traces to O-2, O-3, O-4, O-5, and O-6: the source computes NFKD unconditionally, filters unconditionally, handles already-NFKD input, preserves non-combining characters in order, and makes the precomposed/decomposed n-with-tilde examples agree.

No source edit beyond V1 is justified. The FVK audit did not find an unmet in-domain behavior for `strip_accents_unicode`.

## Decision: scope the formal audit to the changed helper and call path

The FVK artifacts focus on `strip_accents_unicode` and its vectorizer dispatch path rather than all of scikit-learn. This traces to F-001 and F-002, which localize the issue and confirmation to the helper's value contract, and to O-7, which covers the public call path affected by `strip_accents='unicode'`.

## Decision: do not reintroduce an optimization

I considered whether to preserve the old fast path for inputs where normalization is a no-op. F-003 rejects that exact branch because it conflicts with O-4: already-NFKD inputs can still contain combining marks. A future optimization would need to prove O-3 for all already-normalized inputs, not just check `normalized == s`.

## Decision: keep public API and call path unchanged

The audit found no reason to change the helper signature, exports, or vectorizer dispatch. This traces to F-002 and O-7. `build_preprocessor` still maps `strip_accents='unicode'` to `strip_accents_unicode`, and the helper still accepts one argument.

## Decision: do not add or modify tests

F-005 identifies the useful regression tests, especially `strip_accents_unicode(chr(110) + chr(771)) == chr(110)`, but O-8 records the benchmark rule that test files must not be modified. Therefore no test edits were made.

## Decision: label the proof constructed, not machine-checked

The FVK artifacts include `fvk/mini-python-unicode.k`, `fvk/strip-accents-unicode-spec.k`, and the exact commands to run later, but no K tooling was executed. This follows O-9 and the no-execution instruction. The proof conclusion is an audit result over the written claims and source inspection, not a machine-checked `#Top`.

## Artifact summary

The requested five artifacts are complete:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

Additional FVK adequacy and formal-core artifacts were added because the FVK documentation marks them as required for a valid run.
This traces to F-006, O-9, and O-10.
