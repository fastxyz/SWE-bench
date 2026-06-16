# SPEC: PIE800 unnecessary spread fixer

Status: constructed for audit, not machine-checked.

## Scope

This FVK pass audits `repo/crates/ruff_linter/src/rules/flake8_pie/rules/unnecessary_spread.rs`, specifically:

- `unnecessary_spread`
- `unnecessary_spread_fix`
- `trailing_edits`
- `empty_spread_edit`
- `following_item_start`
- `trailing_comma_end`

The verified observable is the source edit set produced for a dict item whose key is `None` and whose value is an `Expr::Dict`, i.e. a Python dict spread of a dict literal.

## Public Intent Spec

1. PIE800 should flag unnecessary dictionary unpacking when a dict literal is spread into another dict.
2. The autofix should remove the redundant spread wrapper while preserving the inner dict entries for non-empty dict literals.
3. The autofix must not introduce invalid syntax.
4. Parenthesized dict literal spreads are in-domain. The issue example `**({"count": 1 if include_count else {}})` must not leave the closing `)` behind.
5. Empty dict literal spreads are in-domain because the implementation already has an explicit empty-dict branch and `**{}` contributes no entries to the containing dict.
6. Existing fixture evidence for non-empty spreads shows that comments inside the inner dict entries should remain attached to those entries.

## Public Evidence Ledger

| ID | Source | Evidence | Obligation | Status |
| -- | -- | -- | -- | -- |
| I1 | `benchmark/PROBLEM.md` | "Fix introduced a syntax error with PIE800" | The fix must preserve Python syntax. | Encoded by PO2, PO4. |
| I2 | `benchmark/PROBLEM.md` | "This wasn't removed" pointing at `)` | Parenthesized spread dict fixes must remove matching closing parentheses. | Encoded by PO2. |
| I3 | Rule docs in source | "Unpacking a dictionary into another dictionary is redundant. The unpacking operator can be removed" | Non-empty spread dict fixes should expose the inner items, not remove them. | Encoded by PO3. |
| I4 | Public fixture snapshot | `"bar": 10` and surrounding comments are preserved after fixing `**{...}` | Non-empty inner entries and their comments must be preserved. | Encoded by PO3. |
| I5 | Implementation branch and Python dict semantics | Empty `**{}` contributes no key/value entries. | Empty spreads should be removed as an item, including the necessary separator. | Encoded by PO4. |
| I6 | FVK boundary guidance | Empty/boundary cases must be considered when the contract covers a family. | First, middle, last, and only empty spread item positions are in scope. | Encoded by PO4. |

## Domain

Inputs are token streams corresponding to a valid Python dict item satisfying all of the following:

- The outer dict item is a spread item (`key.is_none()`).
- The spread value is an `Expr::Dict`.
- The `**` token preceding the value can be found after `prev_end`.
- The opening `{` of the inner dict can be found between the `**` token and `dict.end()`.
- Any wrapper parentheses between `**` and `{` are ordinary non-trivia `(` tokens with matching non-trivia `)` tokens after the inner `}`.
- For empty spread removal, `is_first` and `is_last` correctly describe the item's position in the outer dict item list.

If these token-structure preconditions are not met, the intended behavior is to return no fix rather than emit a partial unsafe edit.

## Required Behavior

### Non-empty spread dict

For a spread item shaped like:

```text
** ( ... ( { inner-items [,] } ) ... )
```

where the count of wrapper `(` tokens is `p >= 0`, the fix must:

- delete from the `**` token through the inner opening `{`;
- delete an optional trailing comma inside the inner dict before the inner `}`;
- delete the inner closing `}`;
- delete exactly `p` closing `)` tokens after that `}`;
- preserve the inner dict item text between `{` and `}`;
- preserve the outer item separator after the spread item.

### Empty spread dict

For an empty spread item shaped like:

```text
** ( ... ( { } ) ... )
```

where the count of wrapper `(` tokens is `p >= 0`, the fix must remove the empty spread as an outer dict item:

- only item: delete the spread and an optional trailing comma;
- first but not last: delete the spread and the following separator up to the next item;
- middle: delete the spread and following separator up to the next item, preserving the previous separator;
- last but not first: delete the preceding separator through the spread, preserving an existing trailing comma if one follows the spread.

## Formal Core

The file `fvk/mini-pie800-fixer.k` contains a small token-shape semantics for the relevant edit cases. The file `fvk/unnecessary-spread-spec.k` contains K-style claims for:

- `NON-EMPTY-BALANCED`
- `EMPTY-ONLY`
- `EMPTY-FIRST`
- `EMPTY-MIDDLE`
- `EMPTY-LAST`

The abstraction is intentionally token-level, not a full Rust or Python semantics. It keeps the property under verification visible: whether the fix result is syntactically valid for the relevant spread-wrapper and separator cases.

## Adequacy Audit

The formal English above matches the public intent:

- Parenthesized non-empty spread handling directly addresses I1 and I2.
- Non-empty entry preservation directly addresses I3 and I4.
- Empty spread separator handling is not named in the issue example, but is required by I3, I5, and I6 because empty dict spreads are a member of the same fixer family and otherwise produce the same class of syntax-error failure.

No public API, trait method, or cross-module signature changed. The compatibility audit is therefore limited to internal call sites of `unnecessary_spread_fix`, all of which are updated in this file.
