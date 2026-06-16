# FVK Specification: F523 Empty `str.format` Fix

Status: constructed from public issue text and source inspection; not machine-checked.

## Scope

The audited unit is the F523 autofix path for unused positional arguments in
`str.format` calls:

- `FormatSummary::try_from` in `repo/crates/ruff_linter/src/rules/pyflakes/format.rs`
- `remove_unused_positional_arguments_from_format_call` in
  `repo/crates/ruff_linter/src/rules/pyflakes/fixes.rs`
- its F523 callsite in `repo/crates/ruff_linter/src/rules/pyflakes/rules/strings.rs`

The checker decides whether a positional argument is unused. This spec covers
the edit chosen after the checker has already decided the unused positional
argument indexes are fixable.

## Intent Spec

I1. From `benchmark/PROBLEM.md`: F523's code fix currently leaves an empty
`.format()` call. The given example says `"Hello".format("world")` should become
`"Hello"`, not `"Hello".format()`.

I2. From the F523 rule comment in `strings.rs`: unused positional arguments in
`str.format` calls are redundant and should be removed.

I3. From Python `str.format` semantics, mirrored by the in-repo parser:
formatting can still do work with zero arguments. In particular, escaped braces
such as `{{` and `}}` are normalized, and fields with missing arguments still
matter because they would remain formatting operations or errors.

I4. Frame condition: F523 is a positional-argument rule. It must not erase
remaining keyword arguments or erase a `.format(...)` call whose remaining format
operation is semantically relevant.

## Public Evidence Ledger

| ID | Source | Evidence | Obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt | `"Hello".format("world")` should be turned into `"Hello"` | When all explicit positional arguments are unused and the format operation is empty, drop `.format(...)`. | Encoded by PO1 |
| E2 | rule docs in source | "Unused positional arguments are redundant... They should be removed." | Remove unused positional arguments without otherwise changing format semantics. | Encoded by PO1, PO4 |
| E3 | parser implementation | `parse_literal_single` maps doubled braces to one literal brace. | A no-field format string is not necessarily identity-preserving. | Encoded by PO3 |
| E4 | rule boundary | F523 is separate from F522/F524. | Do not use F523 to erase keyword placeholders, missing placeholder behavior, or remaining keyword arguments. | Encoded by PO2, PO4 |

## Contract

Let:

- `unused_arguments` be the explicit positional argument indexes selected by F523.
- `args_len` be the number of explicit positional arguments in the call.
- `keywords_empty` mean the call has no keyword arguments, including no `**kwargs`.
- `no_fields` mean `FormatSummary.autos`, `FormatSummary.indices`, and
  `FormatSummary.keywords` are all empty.
- `literal_identity` mean parsing the format template yields either no parts for
  the empty string or exactly one literal part equal to the original string
  literal value.

The special empty-call edit is valid exactly when all of these hold:

1. `unused_arguments` is non-empty.
2. `keywords_empty`.
3. `no_fields`.
4. `literal_identity`.
5. Every explicit positional argument index is in `unused_arguments`.

Postcondition A: If the special condition holds, the edit replaces the whole
`.format(...)` call range with the source text of the attribute receiver. Example:
`"Hello".format("world")` becomes `"Hello"`.

Postcondition B: If the special condition does not hold, this fix helper must
fall back to the existing CST rewrite that removes only the unused positional
arguments from the call.

## Formal Core

The abstract K model in `fvk/mini-f523-format-fix.k` represents only the boolean
decision that chooses between `dropFormatCall()` and `removePositionalArguments()`.
The claims in `fvk/f523-format-fix-spec.k` cover:

- the issue case where dropping the full call is required;
- parsed fields, where dropping the full call is forbidden;
- escaped-brace normalization, where dropping the full call is forbidden;
- remaining keyword arguments, where dropping the full call is forbidden.

Exact commands to machine-check later, not run in this session:

```sh
kompile fvk/mini-f523-format-fix.k --backend haskell
kprove fvk/f523-format-fix-spec.k --definition fvk/mini-f523-format-fix-kompiled
```
