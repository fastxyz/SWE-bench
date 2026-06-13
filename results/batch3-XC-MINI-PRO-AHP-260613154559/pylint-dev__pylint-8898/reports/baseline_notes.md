# Baseline notes — pylint-dev__pylint-8898

## Issue

`bad-name-rgxs` (and any option of type `regexp_csv`, e.g. `good-names-rgxs`)
"mangles regular expressions with commas". Because the option value is treated
as a *comma-separated list* of regexes, a single regex that legitimately
contains a comma — only quantifiers do, e.g. `{1,3}` — is split in the middle.
A config such as

```ini
[tool.pylint.basic]
bad-name-rgxs = "(foo{1,3})"
```

was split into `(foo{1` and `3})`, each of which is an invalid regex, producing
either a hard crash (older versions) or, at this commit, an
`argparse.ArgumentTypeError`. Either way, the user cannot express a valid regex
that uses a comma quantifier.

## Root cause

`pylint/config/argument.py::_regexp_csv_transfomer` split the raw option string
with `_csv_transformer` → `pylint_utils._check_csv` → `_splitstrip`, which does a
naive `value.split(",")`. That splitter has no notion of regex syntax, so commas
inside a `{m,n}` quantifier were treated as list separators.

At this commit the crash itself was already softened: each split piece is run
through `_regex_transformer`, which converts a raw `re.error` into a friendly
`argparse.ArgumentTypeError`. But the *mangling* — splitting inside the
quantifier — was still present, so valid regexes containing commas remained
impossible to express. This matches the maintainer discussion in the issue,
which converged on "don't split on a comma that sits inside an unclosed `{`".

## Changes

### `pylint/utils/utils.py`
- Added `Iterable` to the `collections.abc` import.
- Added `_check_regexp_csv(value)`: a comma splitter that is aware of `{...}`
  quantifiers. It walks the string character by character, tracking whether it
  is inside an open curly brace (`open_curly`); a comma only starts a new regex
  when `open_curly` is `False`. Each resulting fragment is `"".join`-ed and
  `.strip()`-ed (preserving the existing "strip surrounding whitespace"
  behavior of `_splitstrip`, so `foo, bar` still yields `foo` and `bar`). Like
  `_check_csv`, a list/tuple input is passed through unchanged. The function is
  a generator returning `Iterable[str]`. A `None` sentinel marks "start a new
  fragment", and trailing/leading/duplicate commas leave `None` entries that are
  filtered out, mirroring `_splitstrip`'s discarding of empty fields.

### `pylint/utils/__init__.py`
- Re-exported `_check_regexp_csv` (added to both the import block and `__all__`)
  so it is reachable as `pylint.utils._check_regexp_csv`, consistent with the
  existing `_check_csv` export.

### `pylint/config/argument.py`
- `_regexp_csv_transfomer` now iterates over `pylint_utils._check_regexp_csv(value)`
  instead of `_csv_transformer(value)`. Each fragment is still validated/compiled
  by `_regex_transformer`, so a genuinely invalid regex still produces a clean
  `argparse.ArgumentTypeError` rather than a traceback.

### `doc/whatsnew/fragments/8898.bugfix`
- Added a towncrier changelog fragment describing the fix (closes #8898).

## Worked example

`(foo{1,3})` → `_check_regexp_csv` keeps it whole → `['(foo{1,3})']` → compiles
fine. `(foo{1,3}),(bar{4,5})` → `['(foo{1,3})', '(bar{4,5})']`. A plain list
`a,b` still → `['a', 'b']`, and `foo, bar` (space after comma) still →
`['foo', 'bar']`.

## Assumptions / alternatives considered

- **Scope: only `regexp_csv`, not `regexp_paths_csv`.** The issue and the
  maintainer discussion are specifically about `bad-name-rgxs` /
  `good-names-rgxs` (type `regexp_csv`). `_regexp_paths_csv_transfomer` has the
  same theoretical weakness, but path regexes rarely use `{m,n}` quantifiers,
  and the task asks for a minimal, targeted change, so it was left untouched.
- **Quantifier-aware splitting vs. removing CSV behavior.** Maintainers debated
  dropping comma-splitting entirely (telling users to join regexes with `|`) and
  deprecating these options. That is a larger breaking change deferred to a
  separate effort; the chosen fix is the agreed-upon short-term patch that
  preserves backward-compatible list behavior while no longer breaking commas
  inside quantifiers (the prototype `split_on_commas` from the issue thread,
  cleaned up).
- **Tracking only `{` (curly braces), not `(`/`[`.** In Python regex syntax a
  bare comma is only meaningful inside a `{m,n}` quantifier; commas inside `(...)`
  or `[...]` are not special and a user separating two regexes would write the
  comma outside any quantifier. Tracking only `{`/`}` is therefore sufficient
  and matches the agreed design. Nested/again-opened braces are handled by the
  simple boolean because regex quantifiers do not nest.
- **Stripping each fragment.** Kept to preserve the long-standing behavior of
  `_splitstrip` (whitespace around list items is insignificant). A regex needing
  literal leading/trailing spaces would use `\s`/`[ ]`, so this does not regress
  realistic patterns.
- **Used a `current = regexps[-1]` local** instead of indexing twice; purely for
  readability and to let static type checkers narrow the `Optional` away.
