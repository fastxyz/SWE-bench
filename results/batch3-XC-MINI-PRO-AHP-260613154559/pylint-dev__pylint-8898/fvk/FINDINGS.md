# FINDINGS — `_check_regexp_csv` / `_regexp_csv_transfomer`

Plain-language findings from `/formalize` + `/verify`, each as
`input → observed vs expected`. The Findings report does **not** depend on
machine-checking (FVK Benefit 2). Severity: 🔴 bug · 🟡 latent/edge · 🟢
positive/by-design · ⚪ informational.

Legend for status: **V1** = state after the first fix; **V2** = state after this
audit's edit.

---

## F1 🔴→🟢 Original bug (the issue) — FIXED in V1, confirmed in V2

* input: `bad-name-rgxs = "(foo{1,3})"`
* observed (pre-fix, `_splitstrip`): split on the comma into `(foo{1` and
  `3})`; each is an invalid regex → `re.error` / crash (2.14) or
  `argparse.ArgumentTypeError` (this commit).
* expected: a single regex `(foo{1,3})`, compiled successfully.
* V1/V2: `_check_regexp_csv("(foo{1,3})")` keeps the comma inside the `{}`,
  yielding the one field `(foo{1,3})`. ✔
* Multi-regex still works: `"(foo{1,3}),(bar{1,2})"` → `["(foo{1,3})",
  "(bar{1,2})"]`; `"foo, bar"` → `["foo", "bar"]`. ✔

## F2 🔴→🟢 Regression introduced by V1: empty/whitespace fields became a match-all regex — FIXED in V2

This is the central audit finding. Writing the spec in `SPEC.md` §2 — "generalize
`_splitstrip`: split / strip / **discard empty fields**" — exposed that V1 kept
the *strip* but dropped the *discard-empty* half of `_splitstrip`'s contract.

* input: `bad-names-rgxs = "a, ,b"` (a whitespace-only middle field)
  * observed (V1): `["a", "", "b"]` → `_regex_transformer("")` =
    `re.compile("")`, an **empty pattern that matches every name**, so every
    identifier is reported bad/good. No error is raised — silent and worst-case.
  * observed (original pylint, `_splitstrip`): `["a", "b"]` — the empty field is
    discarded.
  * expected (spec `SPLIT`): `["a", "b"]`.
* input: `"  "` (whitespace only)
  * observed (V1): `[""]` (one match-all pattern); expected: `[]`.
* Note: a **truly** empty field from *consecutive* commas (`"a,,b"`) was already
  fine in V1 — it produces a `None` sentinel, which V1 filtered — so the gap was
  specifically **whitespace-only** fields. That asymmetry is itself a smell the
  spec flagged.
* V2 fix: after `"".join(...).strip()`, skip the field when it is empty
  (`pylint/utils/utils.py`). Restores the full `_splitstrip` contract. Maps
  directly to proof obligation **PO6** (the only obligation V1 failed).
* The "worst scenario" the original reporter warned about ("silently create
  [something] instead of erroring out") is exactly this match-all case; V2
  removes it.

## F3 🟢 By-design limitation: a comma inside an *unclosed* `{` is never a separator

* input: `"foo{1,2"` (no closing `}`)
  * observed (V1/V2): one field `"foo{1,2"` (the comma is protected by the open
    `{`). Under the old `_splitstrip` it was `["foo{1", "2"]`.
  * Both `foo{1,2` and `foo{1` are *valid* regexes (Python treats an incomplete
    `{…` as the literal `{`), so neither path errors; they just disagree on the
    split.
* This is the **explicitly agreed heuristic** from the issue thread ("not
  splitting on a comma if it's inside an unclosed `{`"). It is intentional, not a
  bug; documented here and routed to ITERATION_GUIDANCE as an UltimatePowers
  question (should an unbalanced `{` be rejected?). **Kept as-is.**

## F4 🟡 Same latent comma-in-quantifier bug exists in `_regexp_paths_csv_transfomer` — intentionally OUT OF SCOPE

* input: `ignore-paths = "a/b{1,2}/c"` (type `regexp_paths_csv`)
  * observed (V1/V2, unchanged): still uses the naïve `_csv_transformer`, so it
    splits on the inner comma and mangles the path regex — the *same* class of
    bug as F1.
* expected long-term: paths could reuse `_check_regexp_csv`.
* Decision: **not changed.** The issue, the maintainer discussion, and the test
  surface all concern `regexp_csv` (`bad-names-rgxs`); path regexes with `{m,n}`
  quantifiers are rare; and `_regexp_paths_csv_transfomer` does extra
  Windows/POSIX path rewriting that would need its own spec. Keeping the change
  minimal and targeted (per task) outweighs speculative breadth. Recorded as a
  follow-up in ITERATION_GUIDANCE.

## F5 🟢 Positive: the `isinstance(value, (list, tuple))` guard enforces the pass-through precondition

* input: a list default such as `["foo", "bar"]`
  * The guard routes list/tuple inputs to `yield from value`, matching
    `_check_csv`. The string-scanning spec (C-STR) is thus only required to hold
    on the in-domain `str` case; the list case is the trivial (C-LIST) contract.
  This is the "input-validation guard is a no-op on the verified domain" pattern
  from formalize.md §5 — a positive finding, not a bug.

## F6 ⚪ Interface: the function is a generator (`Iterable[str]`), single-use

* `_check_regexp_csv` `yield`s; its result is a one-shot iterator. The only
  production caller, `_regexp_csv_transfomer`, materializes it into a list
  immediately, so this is safe. Anyone testing/using the helper directly must
  iterate once or wrap in `list(...)`; it must not be re-iterated. Behavior
  (the produced values) is identical to a list — only re-iteration differs.
  No change; noted so a future caller doesn't assume re-iterability.

## F7 ⚪ Correctness relies on Python list aliasing (`current = regexps[-1]`)

* `current = regexps[-1]` aliases the **same** mutable list object as the last
  segment; `current.append(char)` is observed through `regexps[-1]`. This is
  correct CPython behavior and is the intended mechanism, but it is a non-obvious
  invariant: were `current` ever rebound to a *copy*, the loop would silently
  drop characters. The mini-Python model encodes it as an explicit
  "update last segment of `regexps`" rule (value sorts don't alias). Flagged so
  the alias is a conscious, documented part of the trusted base — not a hidden
  assumption. No code change; correct as written.

## F8 ⚪ `str.strip()` only trims whitespace, so internal whitespace is preserved

* input: `"a b, c"` → `["a b", "c"]`. Leading/trailing whitespace per field is
  removed (matching `_splitstrip`); whitespace *inside* a field is kept. Regexes
  for identifier names don't contain spaces, and a deliberate space can be
  written `\s`/`[ ]`, so this matches intent. Informational only.

---

## Spec-difficulty signal (Benefit 2 meta-finding)

A *clean* spec was writable — the function **does** generalize `_splitstrip`
(`SPLIT` in §2) — which is itself a good sign. The **one** point of friction was
the empty-field clause: V1 could not be given a clean postcondition without
either (a) admitting an empty-string output field, or (b) adding the
empty-filter. The spec refused to paper over (a) — an empty pattern is
semantically a match-everything regex, never an intended "name pattern" — so the
difficulty pointed straight at the real defect F2. That is the methodology
working as intended: the spec's awkwardness localized the bug.
