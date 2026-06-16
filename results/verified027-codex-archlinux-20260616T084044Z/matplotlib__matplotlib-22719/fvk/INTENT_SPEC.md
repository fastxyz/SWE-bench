# Intent Spec

Status: constructed, not machine-checked.

## Required behavior from public intent

I1. Empty data passed through an axis that already has string category units is
in scope. Evidence: the reproduction calls `ax.xaxis.update_units(["a", "b"])`
then `ax.plot([], [])`.

I2. Empty data must not trigger the numeric pass-through deprecation warning in
the string category converter. Evidence: the issue describes that warning for
`ax.plot([], [])` as "a false alarm or a non-actionable warning" and says the
empty-data edge case was not anticipated.

I3. Empty data should continue to produce an artist with no data rather than a
conversion failure. Evidence: expected outcome says it should "continue
producing artists with no data" or otherwise report an actionable problem; the
reported deprecation-to-`ConversionError` chain is the symptom to remove.

I4. Non-empty numeric values passed through string category converters remain a
deprecated pass-through. Evidence: existing public tests
`test_convert_one_number` and `test_convert_float_array` expect
`MatplotlibDeprecationWarning`.

I5. Non-empty categorical values still update the category mapping and preserve
existing type validation. Evidence: `category.py` docstrings define `UnitData`
as the string-to-integer mapping, and public tests cover string conversion,
mixed-type failures, and mapping order.

I6. The informational "all parseable as floats or dates" log only has semantic
content for non-empty data. Evidence: the public hint pairs the empty
deprecation fix with the same `data.size` guard for `UnitData.update`.

I7. Public API signatures and call shapes must remain compatible. Evidence:
the issue requests behavior repair for empty data, not a new converter API.
