# Proof Obligations

Status: constructed, not machine-checked.

## PO1 - Inline Typed Container Split

For any recognized typed field argument with at least two whitespace-separated
tokens, the final token is the parameter name and the preceding tokens are the
type expression.

- Public evidence: E1-E3, E6.
- K claims: C1, C2.
- Source witness: `fieldarg.rsplit(None, 1)`.
- Status: satisfied by V1.

## PO2 - Single-Word Inline Type Regression

For `:param str name:`, the parameter name remains `name` and the type remains
`str`.

- Public evidence: E4.
- K claim: C3.
- Source witness: `fieldarg.rsplit(None, 1)` gives `("str", "name")`.
- Status: satisfied by V1.

## PO3 - Separate Type Field Frame

Existing `:param name:` plus `:type name: TYPE` behavior remains unchanged.

- Public evidence: E5-E6.
- Formal status: frame obligation; V1 only changes the inline typed branch and
  leaves the `is_typefield` collection path unchanged.
- Status: satisfied by source inspection.

## PO4 - Autodoc Annotation Merge Name Consistency

For inline typed `:param type name:` fields, autodoc's type-hint merger must
associate both the description and existing type with `name`, not with part of
the type expression.

- Public/source evidence: E8.
- K claims: C5, C6.
- Source witness: both scanner paths use `parts[-1]` when `len(parts) > 2`.
- Status: satisfied by V1.

## PO5 - Compatibility

The fix must not alter public signatures or directive field aliases, and it
must preserve documented one-word inline typed behavior.

- Public evidence: E4, E9.
- Audit: `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`.
- Status: satisfied.

## PO6 - FVK Honesty Gate

The proof artifacts must state that they are constructed, not machine-checked,
and no tests or K tooling may be run in this environment.

- Public evidence: E9 and task no-execution rule.
- Status: satisfied by `PROOF.md`; no execution was performed.
