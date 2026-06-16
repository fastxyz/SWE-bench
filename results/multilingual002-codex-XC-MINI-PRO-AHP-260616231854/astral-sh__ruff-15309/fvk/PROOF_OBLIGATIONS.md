# FVK Proof Obligations

Status legend: discharged means discharged by static source reasoning and the
constructed proof sketch; not machine-checked.

## PO1: Drop empty identity-preserving format calls

Statement: If all explicit positional arguments are unused, no keyword arguments
remain, the parsed format summary has no fields, and no-argument formatting is
identity-preserving, then the fix must replace the whole `.format(...)` call
with the receiver source.

Evidence: `benchmark/PROBLEM.md` example `"Hello".format("world")` => `"Hello"`.

Source discharge: `fixes.rs` now returns `Edit::range_replacement(locator.slice(value.range()).to_string(), call.range())` under this condition.

Status: discharged.

## PO2: Do not drop calls when parsed fields remain

Statement: If `FormatSummary.autos`, `indices`, or `keywords` is non-empty, F523
must not replace the full call with the receiver.

Evidence: F523 removes extra positional arguments; remaining fields continue to
belong to the format operation and may be handled by F524 or at runtime.

Source discharge: the special branch in `fixes.rs` requires all three summary
collections to be empty.

Status: discharged.

## PO3: Do not drop calls when no-argument formatting is not identity-preserving

Statement: If parsing the format template changes literal text, as with doubled
braces, F523 must not replace the full call with the receiver.

Evidence: the in-repo format parser turns doubled braces into single literal
braces.

Source discharge: `FormatSummary::try_from` computes `is_literal_identity`, and
`fixes.rs` requires it before dropping the call.

Status: discharged.

## PO4: Preserve remaining non-positional arguments

Statement: If keyword arguments remain, including `**kwargs`, F523 must remove
only unused positional arguments and must keep the `.format(...)` call.

Evidence: F523 is a positional-argument rule; F522 handles extra named
arguments.

Source discharge: the special branch in `fixes.rs` requires
`call.arguments.keywords.is_empty()`.

Status: discharged.

## PO5: The identity flag is correctly derived from parsed format parts

Statement: `FormatSummary::is_literal_identity` is true only for an empty
template or a single parsed literal part exactly equal to the original string
literal value.

Evidence: a template with fields produces field parts; a template with escaped
braces produces a literal part that differs from the original doubled-brace
value.

Source discharge: `format.rs` matches `format_string.format_parts.as_slice()`
against `[]` and `[FormatPart::Literal(value)] if value == literal`.

Status: discharged for the modeled parser cases.

## PO6: The fix helper uses the same summary as the checker

Statement: The branch decision must be based on the `FormatSummary` parsed for
the same `.format` call used to calculate unused positional arguments.

Evidence: otherwise a stale or absent summary could prove the wrong string.

Source discharge: `strings.rs` passes its existing `summary` reference into
`remove_unused_positional_arguments_from_format_call`.

Status: discharged.

## PO7: Existing fallback behavior is preserved

Statement: Outside the special empty identity case, the pre-existing CST
argument-removal behavior must remain the active fix path.

Evidence: F523 examples with remaining used positional arguments should continue
to remove only trailing extras.

Source discharge: the previous `transform_expression` block is unchanged and is
still the fallthrough path.

Status: discharged.

## PO8: Machine-checking remains pending

Statement: The K proof commands must be emitted but not run in this session.

Evidence: the user explicitly forbids running K framework tooling.

Source discharge: commands are written in `SPEC.md` and `PROOF.md`; no K commands
were executed.

Status: pending external machine check.
