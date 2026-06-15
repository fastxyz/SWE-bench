# FVK Spec

Status: constructed, not machine-checked.

## Scope

The audit targets the behavior changed by the Django issue:

- `django.contrib.admindocs.utils.replace_named_groups()`
- `django.contrib.admindocs.utils.replace_unnamed_groups()`
- `django.contrib.admindocs.views.simplify_regex()` as the public composition

The formal core is in `mini-regex-groups.k` and `admindocs-regex-spec.k`. The
mini-semantics abstracts away full Python execution and full regular-expression
parsing. It models the span-scanning and reconstruction properties needed to
prove the fix over finite, balanced URL regex pattern strings.

## Public intent ledger

The ledger is mirrored in `PUBLIC_EVIDENCE_LEDGER.md`. The essential
obligations are:

- E1: final named groups must be replaced without requiring a trailing slash.
- E2: the issue example must simplify to readable path text with both group
  names substituted.
- E3: final unnamed groups must receive the analogous treatment.
- E4: all outermost unnamed groups must be replaced, with nested groups consumed
  by the outer group and with intervening text copied exactly once.
- E5: existing public-test behavior for followed groups, nested groups, anchors,
  and optional slashes must be preserved.
- E6: helper signatures and `simplify_regex()` call order must remain compatible.

## Contracts

### `replace_named_groups(pattern)`

Precondition: `pattern` is a finite string and each named group in scope has a
balanced closing parenthesis under the helper's existing escaped-parenthesis
rule.

Postcondition: every complete named group span
`(?P<name>body)` is replaced by `<name>`. This includes the case where the span's
closing `)` is the final character of `pattern`. Text outside replaced spans is
preserved.

### `replace_unnamed_groups(pattern)`

Precondition: `pattern` is a finite string in the post-`replace_named_groups()`
pipeline state, and each unnamed group in scope has a balanced closing
parenthesis under the helper's existing escaped-parenthesis rule.

Postcondition: every outermost non-overlapping unnamed group span is replaced by
`<var>`. Adjacent top-level groups are both replaced. Nested unnamed groups do
not create additional replacements when an enclosing unnamed group is already
selected. Text before, between, and after selected spans is preserved exactly
once.

### `simplify_regex(pattern)`

Precondition: `pattern` is in the helper domain above.

Postcondition: the function returns the composition:

1. named group replacement,
2. unnamed group replacement,
3. removal of `^`, `$`, and `?`,
4. insertion of a leading `/` when absent.

The issue example therefore reaches `/entries/<pk>/relationships/<related_field>`
when passed through Django's `simplify_regex()` wrapper.

## Frame conditions

- No public signature changes.
- No change to the order of `simplify_regex()` helper calls.
- No source edits to tests.
- No behavior change is intended for patterns with no complete capture groups.

## Residual risk

The proof is constructed only. The specified K commands are recorded in
`PROOF.md`, but were not run. Full Python and full `re` semantics are outside the
mini-model; the proof covers the changed span logic and the composition surface
required by the public issue.
