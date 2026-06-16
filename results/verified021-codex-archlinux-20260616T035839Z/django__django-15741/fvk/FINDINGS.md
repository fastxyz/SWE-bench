# FVK Findings

Status: constructed, not machine-checked.

## F-001: Lazy string reached string-only lookup before V1

Classification: code bug, resolved by V1.

Evidence: public issue E-001 through E-003.

Input: `format_type = gettext_lazy("Y-m-d")`, localization enabled, cache miss,
and no localized module attribute named `"Y-m-d"`.

Observed before V1: the lazy `Promise` object could be passed directly to
`getattr(module, format_type, None)`, producing
`TypeError: getattr(): attribute name must be string`.

Expected: the lazy string behaves like `"Y-m-d"` and reaches the arbitrary
format fallback, returning `"Y-m-d"` to the date formatting path.

Resolution: V1 converts `Promise` to `str` before cache lookup, module lookup,
settings lookup, and arbitrary-format fallback. This discharges PO-001,
PO-002, and PO-003.

## F-002: Patching only the template date filter would be under-scoped

Classification: localization of fix, resolved by V1.

Evidence: public issue E-001 and E-004.

Input: any direct caller of `django.utils.formats.get_format()` or helper caller
such as `time_format()` that passes a lazy string.

Observed risk if the fix were only in `django.template.defaultfilters.date`:
direct callers and other helpers would still be able to send a lazy object to
`get_format()` and hit the same string-only lookup failure.

Expected: the shared helper accepts lazy string parameters consistently.

Resolution: V1 patches `get_format()` itself. This discharges PO-006.

## F-003: Broad coercion of arbitrary non-string objects is not justified

Classification: frame-condition finding, resolved by keeping V1 targeted.

Evidence: public issue E-001, docstring E-005, and baseline note E-007.

Input: `format_type` is a non-Promise object that is not already a string.

Observed risk in an alternative patch: applying `str(format_type)` to all inputs
would silently change behavior for unrelated invalid inputs such as `None`,
integers, or custom objects.

Expected: only Django lazy `Promise` values, the issue's in-domain lazy string
type, are normalized by the fix.

Resolution: V1 uses `isinstance(format_type, Promise)` before `str()`. This
discharges PO-005.

## F-004: Proof is constructed but not machine-checked

Classification: proof capability / honesty caveat, open until K tooling is run.

Evidence: FVK verify guidance and this session's no-execution constraint.

Input: the FVK K artifacts in `fvk/mini-django-formats.k` and
`fvk/get-format-spec.k`.

Observed: commands are emitted but not executed.

Expected before claiming machine verification: run the emitted `kompile`,
`kast`, and `kprove` commands and obtain `#Top`.

Resolution: no source change is implied. Do not remove tests based on this proof
until a future machine check succeeds.
