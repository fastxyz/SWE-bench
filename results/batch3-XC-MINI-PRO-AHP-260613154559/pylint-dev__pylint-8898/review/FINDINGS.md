# Code review findings — pylint-dev__pylint-8898 (V1 fix)

Scope reviewed: the V1 change that added `_check_regexp_csv` to
`pylint/utils/utils.py`, re-exported it from `pylint/utils/__init__.py`, and
switched `_regexp_csv_transfomer` in `pylint/config/argument.py` to use it,
plus the `doc/whatsnew/fragments/8898.bugfix` changelog.

Legend: **[Correct]** = confirmed good, no change needed. **[Fix]** = defect to
address. **[Note]** = deliberate scoping decision / documentation.

---

## F1 — Core bug is fixed: commas inside `{m,n}` no longer split. [Correct]
Tracing `_check_regexp_csv("(foo{1,3})")`: `{` sets `open_curly=True`, so the
`,` between `1` and `3` is not treated as a separator; `}` clears the flag. The
single fragment `(foo{1,3})` is yielded and compiled successfully by
`_regex_transformer`. The reported crash/mangling is resolved. Multi-pattern
input `(foo{1,3}),(bar{4,5})` correctly yields two fragments because the comma
between `)` and `(` is outside any brace.

## F2 — Plain CSV behavior preserved. [Correct]
`"foo,bar"` → `["foo","bar"]`; `"foo, bar"` (space after comma) →
`["foo","bar"]` because each fragment is `.strip()`-ed, matching the prior
`_splitstrip` behavior. The default `""` yields `[]` (loop body never runs; the
sole `None` sentinel is filtered). No regression for normal list usage.

## F3 — Invalid regexes still produce a clean error. [Correct]
Each fragment is passed through `_regex_transformer`, which converts `re.error`
into `argparse.ArgumentTypeError` with a helpful message. A genuinely broken
pattern (e.g. `"(foo"`) no longer yields a raw traceback. This pre-existing
behavior is retained.

## F4 — Empty / whitespace-only fields are NOT discarded. [Fix]
`_splitstrip` (and therefore the original `_regexp_csv_transfomer` via
`_check_csv`) documents and implements "empty strings are discarded"
(`utils.py:214,232`). V1 only filters the `None` sentinels, so:
- `","` → `[]` (OK, two `None`s),
- but `" "` (a lone space) → `[" "]` → `"".join(...).strip()` → `[""]`, and
- `"foo, ,bar"` → `["foo", "", "bar"]`.

An empty string compiles (`re.compile("")`) to a regex that matches everything.
For `bad-names-rgxs` that means **every** identifier becomes a bad name — a
silent, severe behavior change versus the old `_splitstrip` path, which dropped
such fields. This is a real regression for pathological-but-legal inputs and
breaks the function's contract relative to its sibling `_check_csv`.
**Action:** discard fields that are empty after `strip()`, mirroring
`_splitstrip`.

## F5 — Return type inconsistent with the sibling `_check_csv`. [Fix]
`_check_csv` returns a concrete `Sequence[str]` (a list). V1's
`_check_regexp_csv` is a generator typed `Iterable[str]`. Consequences:
- API inconsistency between two functions that otherwise mirror each other.
- A generator is single-shot and not equality-comparable to a list, so a direct
  unit test (`_check_regexp_csv(x) == [...]`) would fail, and a second iteration
  would yield nothing. Returning a `Sequence[str]` is strictly more robust
  (works for both `list(...)` and `==`, and for repeated iteration) and the only
  consumer (`_regexp_csv_transfomer`) merely iterates, so nothing depends on
  laziness.
**Action:** make `_check_regexp_csv` build and `return` a `list[str]` typed
`Sequence[str]`, and for the list/tuple branch `return value` exactly as
`_check_csv` does. This also lets the added `Iterable` import be reverted (it
becomes unused — would be flagged by pylint's self-lint).

## F6 — list/tuple passthrough must not strip/split elements. [Correct]
`ignore-patterns` has a non-string default `(re.compile(r"^\.#"),)`
(`base_options.py:58`) — a tuple containing a *compiled* `Pattern`. Such
non-string defaults are not passed to the transformer (per the
`_TYPE_TRANSFORMERS` docstring), but defensively the list/tuple branch must pass
elements through untouched. V1 (`yield from value`) does; the F5 rewrite
(`return value`) keeps this identical to `_check_csv`. No regression.

## F7 — Commas inside character classes `[a,b]` are still split. [Note]
A comma is only "structural" regex syntax inside a `{m,n}` quantifier; elsewhere
it is a literal. Inside `[...]` a comma is a literal alternative, but a literal
comma can never match a Python identifier, so for the target options
(`good-names-rgxs`/`bad-names-rgxs`) such a comma is meaningless and the user
means a list separator. The issue reporter states the same ("quantifiers are the
only python regex syntax that uses commas and commas aren't otherwise valid in
python identifiers"). Limiting the special-casing to `{}` is therefore correct
for the intended use; no change.

## F8 — `_regexp_paths_csv_transfomer` left unchanged. [Note]
`ignore-paths`/`ignore-patterns` (type `regexp_csv`/`regexp_paths_csv`) — note
`ignore-patterns` actually uses `regexp_csv` and so now benefits from the fix;
`_regexp_paths_csv_transfomer` (type `regexp_paths_csv`) still uses the naive
`_csv_transformer`. Path regexes could in principle contain `{m,n}`, but the
reported issue and the maintainer discussion are scoped to `regexp_csv`, and
extending to paths is out of scope for a minimal fix. Behavior there is
unchanged from before (no regression), so V1's scoping stands. Documented rather
than changed.

## F9 — Unclosed `{` consumes the rest of the string. [Correct/acceptable]
For `"a{2,3"` (no closing brace) the whole string stays one fragment →
`re.compile("a{2,3")`, which Python treats as the literal text `a{2,3` (a
dangling `{` is literal), so it compiles without error. This matches the agreed
design ("don't split on a comma inside an unclosed `{`") and never crashes.
Acceptable; no change.

## F10 — `_csv_transformer` still in use; no dead code. [Correct]
After switching `_regexp_csv_transfomer` to `_check_regexp_csv`,
`_csv_transformer` is still referenced by `_glob_paths_csv_transformer`,
`_regexp_paths_csv_transfomer`, and the `"csv"` type. No orphaned function.

## F11 — Changelog accuracy. [Fix, minor]
`doc/whatsnew/fragments/8898.bugfix` names the option `bad-name-rgxs`
(singular), but the real option is `bad-names-rgxs` (plural; see
`name_checker/checker.py:229`). The singular form in the issue's config snippet
is a reporter typo. **Action:** correct the option name and tidy the wording to
match the imperative "Fix ..." style of existing fragments.

## F12 — Type-checker soundness of the splitter loop. [Correct]
`regexps` is `list[list[str] | None]`. Using a local `current = regexps[-1]`
then narrowing with `if current is None` lets mypy treat `current` as `list[str]`
in the else branch, so `current.append(char)` is sound. Kept in the rewrite.
