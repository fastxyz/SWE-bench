# Formal Spec English

This paraphrases the nontrivial K claims in `fvk/convert-dx-spec.k`.

## Claim `ALL_NONFINITE_NO_STOP`

For any non-empty original-coordinate sequence and converted-coordinate sequence
with no finite entries, `_convert_dx` selects the first unfiltered original
coordinate and the first unfiltered converted coordinate. It then computes
widths with those representatives. No `StopIteration` result is reachable from
the representative-selection phase.

## Claim `REPRO_SINGLE_NAN`

For the concrete reproduction shape, one scalar width delta with original x
`nan` and converted x `nan`, conversion produces one nonfinite width result
rather than `StopIteration`.

## Claim `MIXED_LEADING_NAN_KEEPS_FIRST_FINITE`

For a sequence whose first element is `nan` but a later element is finite,
representative selection uses the first finite element, not the leading `nan`.
This preserves the pre-existing fix for leading-NaN mixed data.

## Claim `EMPTY_XCONV_UNCHANGED`

When the converted x sequence is empty, `_convert_dx` does not perform
representative selection at all. It returns the direct `convert(dx)` fallback,
matching the existing empty-input branch.

## Frame Conditions

The formalized change does not alter the function signature, caller protocol,
global behavior of `cbook._safe_first_finite`, or the conversion-error fallback
for `ValueError`, `TypeError`, and `AttributeError`.
