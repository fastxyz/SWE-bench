# Formal Spec in English

Status: paraphrase of `select-date-widget-spec.k`.

## EMPTY-TRIPLE

If all three split date components are present and equal to the empty string, `value_from_datadict()` returns `None`.

## PARTIAL-FALLBACK-Y / PARTIAL-FALLBACK-M / PARTIAL-FALLBACK-D

If the year, month, or day component is absent, and the all-empty branch therefore did not apply, `value_from_datadict()` returns the fallback value from `data.get(name)`.

## VALID-COMPLETE

If all three split date components are present and the component triple converts to a valid Python date, `value_from_datadict()` returns the formatted date result.

## VALUE-ERROR-COMPLETE

If all three split date components are present and conversion or date construction raises `ValueError`, `value_from_datadict()` returns the pseudo-ISO invalid-date result.

## OVERFLOW-COMPLETE

If all three split date components are present and date construction raises `OverflowError`, `value_from_datadict()` returns the same pseudo-ISO invalid-date result and does not allow `OverflowError` to escape.

## Frame Conditions

The method signature, public dispatch shape, `files` behavior, and return categories are unchanged. No loop or recursive behavior is present.

