# Formal Spec English

Status: constructed, not machine-checked.

This file paraphrases every nontrivial K claim in
`category-empty-spec.k`.

## CONVERT-EMPTY-VACUOUS-NUMERIC

Starting from an empty normalized data sequence where the all-numeric summary
may be true by vacuous truth, `convert` terminates successfully with result
size `0` and no deprecation warning.

## CONVERT-NONEMPTY-NUMERIC

Starting from a non-empty normalized data sequence whose elements are all
numeric-like and not strings/bytes, `convert` terminates successfully, returns
a converted result of the same size, and emits the existing numeric
pass-through deprecation warning.

## CONVERT-NONEMPTY-CATEGORICAL

Starting from a non-empty normalized data sequence that is not all numeric-like
and is accepted by `UnitData.update`, `convert` terminates successfully,
returns a mapped result of the same size, and emits no numeric pass-through
deprecation warning.

## CONVERT-NONEMPTY-INVALID

Starting from a non-empty normalized data sequence that is not all numeric-like
and is rejected by `UnitData.update`, `convert` terminates with the modeled
validation failure and emits no numeric pass-through deprecation warning.

## UPDATE-EMPTY-CONVERTIBLE

Starting from empty normalized update data where the all-convertible summary
may be true by vacuous truth, `UnitData.update` terminates successfully and
emits no all-convertible informational log.

## UPDATE-NONEMPTY-CONVERTIBLE

Starting from non-empty normalized update data where every inspected value is
parseable as a float or date, `UnitData.update` terminates successfully and
emits the existing all-convertible informational log.
