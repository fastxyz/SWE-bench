# FVK Notes

## Summary

The FVK audit confirmed V1's core approach: keep docutils' include directive in
charge of parsing/insertion while routing the include file read through
Sphinx's `source-read` event. The audit also found two issues that V1 did not
fully discharge, so V2 changes production source in two places.

## Source decisions

### `repo/sphinx/directives/other.py`

Decision: keep V1's include wrapper and strengthen it.

Trace:

- `fvk/FINDINGS.md` F-001 identified that V1 only patched
  `docutils.io.FileInput`. That proves the include read is intercepted only if
  docutils resolves `FileInput` through the module attribute.
- `fvk/PROOF_OBLIGATIONS.md` PO-4 requires interception and restoration for
  both modeled lookup channels: module-level `docutils.io.FileInput` and a
  direct `FileInput` global in `BaseInclude.run`.

Change:

- The helper now inspects `BaseInclude.run.__globals__` and, when that global
  contains the original `FileInput`, temporarily patches it to the wrapper too.
  Both bindings are restored in the existing `finally` block.

Decision: keep delegation to `super().run()`.

Trace:

- PO-3 requires preservation of docutils include options, dependency recording,
  and insertion behavior.
- F-003 marks full docutils include semantics as outside the mini-K model, so
  source-level delegation is the preservation argument.

### `repo/sphinx/ext/duration.py`

Decision: update `on_source_read()` to record the start time once per document
read.

Trace:

- F-002 identified that additional include-triggered `source-read` events could
  reset `started_at` and undercount the containing document's read duration.
- PO-6 requires duration compatibility with the new event firing pattern.

Change:

- `started_at` is now set only if it is absent from `env.temp_data`; later
  source-read events during the same document read leave it unchanged.

## Decisions to keep V1 behavior

- Standard docutils includes remain an early `return super().run()` path. This
  is required by PO-5 and supported by evidence E8.
- Event docname selection remains `env.path2doc(filename) or env.docname`. This
  discharges PO-2 and matches `SPEC_AUDIT.md`'s default-domain assumption for
  non-source include files.
- No tests were added or edited, per the benchmark instructions and PO-7.

## Verification status

The K artifacts and proof are constructed but not machine-checked. The exact
commands are recorded in `fvk/PROOF.md` and `fvk/ITERATION_GUIDANCE.md`; they
were not executed in this session.
