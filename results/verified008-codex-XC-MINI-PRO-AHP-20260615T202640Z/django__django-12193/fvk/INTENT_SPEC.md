# Intent Spec

Status: constructed from public evidence; not machine-checked.

## Required behavior

1. A `SplitArrayField` backed by `BooleanField` must render each checkbox according to that entry's own backing value. For boolean values, `True` produces a generated `checked` attribute and `False` does not.
2. A generated `checked` attribute from one checkbox render must not be written into the attrs dictionary reused for later subwidgets.
3. `CheckboxInput.get_context()` may add `checked` to the returned widget context when `check_test(value)` is true, but it must not mutate caller-owned `attrs`.
4. Explicit attrs supplied by a caller are still preserved. In particular, if the original attrs already contain `checked`, that explicit request remains visible in the returned context.
5. The public API shape must remain compatible: no signature change for `CheckboxInput.get_context()`, `Widget.get_context()`, or `SplitArrayWidget.get_context()`.

## Domain

The issue's concrete domain is `SplitArrayField(BooleanField)` with existing boolean data. The proof abstracts BooleanField prepared values as `Bool` and abstracts attrs to whether the original attrs already contained `checked`. The proof is partial correctness: if the relevant rendering methods return normally, the postconditions hold. Existing behavior for a custom `check_test` that raises remains outside the normal-return proof and is preserved by the source change.

## Frame conditions

The fix must leave non-`checked` attrs, widget names, value formatting, templates, ids, localization propagation, and public signatures unchanged. The formal core models only the `checked` bit and attrs aliasing; the remaining frame conditions are discharged by source inspection because the V1 diff only inserts `attrs.copy()` before `attrs['checked'] = True`.
