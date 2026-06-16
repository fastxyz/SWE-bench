# FVK Notes

## Decision

V1 stands unchanged. The FVK audit found that the existing source change in
`repo/django/utils/formats.py` is the minimal edit that satisfies the public
intent: normalize Django lazy `Promise` format parameters to `str` inside
`get_format()` before the value is used as a cache key, module attribute name,
settings attribute name, or arbitrary-format fallback.

No additional source files were edited during this FVK pass.

## Trace To Findings And Obligations

F-001 identifies the reported bug: a lazy string such as
`gettext_lazy("Y-m-d")` could reach `getattr(module, format_type, None)` as a
non-`str` and raise `TypeError`. PO-001, PO-002, PO-003, and PO-004 require
lazy strings to behave like their concrete string values across cache, localized
module lookup, settings fallback, and arbitrary-format fallback. V1 discharges
these obligations because it converts `Promise` to `str` before all of those
paths.

F-002 shows why the fix must remain in `get_format()` instead of being moved to
`django.template.defaultfilters.date`. PO-006 requires the shared helper to keep
its public signature while accepting lazy string parameters for all callers. V1
meets that requirement and leaves callers unchanged.

F-003 rejects a broader alternative: coercing every `format_type` with `str()`.
PO-005 preserves the frame condition that arbitrary non-Promise, non-string
objects are outside this issue's required domain. V1 meets that condition by
guarding the conversion with `isinstance(format_type, Promise)`.

F-004 records the honesty gate: the K artifacts and proof are constructed but
not machine-checked. PO-007 therefore blocks any claim of machine verification
or test deletion, but it does not require a source change.

## Alternatives Rechecked

Patching only the date template filter was rejected again because it would leave
direct `get_format()` callers and other helper paths exposed, contrary to F-002
and PO-006.

Using unconditional `str(format_type)` was rejected again because it would
change unrelated invalid-input behavior, contrary to F-003 and PO-005.

Moving the `Promise` normalization later was rejected because PO-002 requires
the value to be concrete before both `getattr()` paths and PO-001 also requires
the cache key to be computed from the normalized string.

## FVK Artifacts

The required five artifacts are present:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

The FVK formal core and adequacy support files are also present:

- `fvk/mini-django-formats.k`
- `fvk/get-format-spec.k`
- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`

No tests, Python code, or K tooling were run.
