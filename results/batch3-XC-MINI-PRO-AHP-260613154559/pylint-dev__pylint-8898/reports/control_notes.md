# Control notes — pylint-dev__pylint-8898 (post-review)

This documents the V2 decisions after reviewing the V1 fix. Each decision is
traced to a numbered entry in `review/FINDINGS.md`. `reports/baseline_notes.md`
remains the V1 record.

## Summary of what V1 got right (kept unchanged)

- **Core approach — quantifier-aware comma splitting in `_check_regexp_csv`,
  consumed by `_regexp_csv_transfomer`.** Kept. Traced to **F1** (the reported
  `(foo{1,3})` crash/mangling is resolved and multi-pattern input still splits)
  and **F2** (plain `foo,bar` / `foo, bar` CSV behavior preserved). The
  `open_curly` boolean and `None`-sentinel design are correct.
- **Validation via `_regex_transformer`.** Kept (**F3**): invalid patterns still
  produce a clean `argparse.ArgumentTypeError` instead of a traceback.
- **Scope limited to `{}` quantifiers (not character classes).** Kept as-is
  (**F7**): for identifier-name regexes a literal comma elsewhere can never match
  an identifier, so special-casing only `{m,n}` is the semantically correct
  choice and matches the issue reporter's own analysis.
- **`_regexp_paths_csv_transfomer` left on the naive splitter.** Kept (**F8**):
  the issue and maintainer discussion are scoped to `regexp_csv`; path handling
  is unchanged from before, so there is no regression. Note that `ignore-patterns`
  is type `regexp_csv` and so now benefits from the fix; `ignore-paths`
  (`regexp_paths_csv`) is intentionally untouched.
- **Unclosed `{` consumes the remainder.** Kept (**F9**): `"a{2,3"` compiles as
  literal text in Python's `re`, so it never crashes — acceptable per the agreed
  design.
- **`_csv_transformer` retained.** Confirmed not dead code (**F10**): still used
  by `_glob_paths_csv_transformer`, `_regexp_paths_csv_transfomer`, and the
  `"csv"` type.
- **list/tuple passthrough.** Behavior retained (**F6**): `ignore-patterns`'
  non-string default `(re.compile(r"^\.#"),)` proves the branch must pass
  elements through untouched; the V2 rewrite keeps this identical to `_check_csv`.
- **Local-variable narrowing in the loop.** Kept (**F12**): `current = regexps[-1]`
  keeps the `Optional` narrowing sound for type checkers.

## Changes made in V2

### Change 1 — Discard empty / whitespace-only fields (`pylint/utils/utils.py`)
Addresses **F4**. V1 filtered only the `None` sentinels, so a whitespace-only
field (`" "`, or the middle of `"foo, ,bar"`) survived as `""`, which
`re.compile("")` turns into a *match-everything* regex — for `bad-names-rgxs`
that silently marks every identifier bad. The original code path
(`_check_csv` → `_splitstrip`) explicitly discards empty fields
(`utils.py:214,232`). The rewrite now joins each fragment, drops `None`
sentinels, and skips any fragment that is empty after `strip()`, restoring the
documented contract. Verified traces: `" "` → `[]`, `"foo, ,bar"` →
`["foo","bar"]`, while `"(foo{1,3})"`, `"foo,bar"`, `"foo, bar"`, `""`, and
`","` are unaffected.

### Change 2 — Return a concrete `Sequence[str]`, not a generator (`pylint/utils/utils.py`)
Addresses **F5**. V1 returned a generator typed `Iterable[str]`, inconsistent
with the sibling `_check_csv`, which returns a `Sequence[str]` list. A generator
is single-shot and not equality-comparable to a list, which is fragile for any
direct unit test and for repeated iteration. The function now builds and
`return`s a `list[str]` (typed `Sequence[str]`) and, in the list/tuple branch,
`return value` exactly as `_check_csv` does. The only consumer
(`_regexp_csv_transfomer`) merely iterates, so nothing depended on laziness; the
new form is strictly more robust and API-consistent.

### Change 3 — Revert the now-unused `Iterable` import (`pylint/utils/utils.py`)
Consequence of Change 2 (**F5**). With a `Sequence[str]` return, `Iterable` is no
longer referenced; leaving it would be an unused import flagged by pylint's
self-lint. The import line is restored to `from collections.abc import Sequence`.

### Change 4 — Changelog accuracy (`doc/whatsnew/fragments/8898.bugfix`)
Addresses **F11**. Corrected the option name from the reporter's typo
`bad-name-rgxs` to the real `bad-names-rgxs`, and reworded to the imperative
"Fix ..." style used by existing fragments.

## Net effect

The behavioral fix for the reported issue is unchanged from V1 (commas inside
`{m,n}` quantifiers are preserved). V2 additionally removes a latent
match-everything regression for whitespace-only/empty fields (F4) and aligns the
new helper's return type and import footprint with the existing `_check_csv`
(F5), plus a changelog correction (F11). No public API contract is broken: the
only new symbol, `pylint.utils._check_regexp_csv`, is private and now mirrors
`_check_csv`.
