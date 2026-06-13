# Control notes — V2 review outcome for django__django-15503

This documents the result of the systematic review in `review/FINDINGS.md` and every
decision (changed or kept) that followed from it.

## Summary of outcome

V1 was found **correct and regression-free** for the issue (findings F1–F12). The fix
**stands essentially unchanged**. The only edit in V2 is a **documentation-only comment**
on the `HasKeyOrArrayIndex` helper class (F13). No behavioral code changed.

## Decisions

### D1 — Keep the core fix: navigation-vs-final-key split in `HasKeyLookup.as_sql`
Traces to **F1, F2, F3**. The split (compile navigation with `compile_json_path`, compile
the final key with `compile_json_path_final_key` = object key) is what fixes the reported
bug (F1) while producing byte-identical SQL for all existing non-numeric has_key cases
(F2) and preserving array-index navigation for `value__1__has_key` / `value__d__1__has_key`
(F3). A simpler "never use array paths anywhere in has_key" change was reconsidered and
rejected again here because F3 shows it would break list/array navigation that has explicit
tests. Kept unchanged.

### D2 — Keep `HasKeyOrArrayIndex` and the three migrated call sites
Traces to **F4, F5, F11**. `KeyTransformIsNull` (sqlite/oracle) and
`KeyTransformExact.as_oracle` reuse the existence check for an *extraction* key, where an
integer must stay an array index. `HasKeyOrArrayIndex.as_sql` is provably identical to the
pre-fix `HasKey.as_sql` (F4), so `value__d__0__isnull` and the many base querysets built on
it are unaffected. F5 confirms all three internal `HasKey(...)` constructions were migrated
and no extraction-key check was left on the object-key path. F11 confirms the helper is
never reached on PostgreSQL. Kept unchanged.

### D3 — Keep `compile_json_path_final_key` as `".%s" % json.dumps(key_transform)` (no `str()` coercion)
Traces to **F2, F8**. The exact `json.dumps(key_transform)` form is what makes V1's output
identical to the original `compile_json_path` non-integer branch (F2) — that equivalence is
the backbone of the no-regression argument. F8 analyzed the only input this leaves
imperfect — a *raw non-string* passed to `has_key` (e.g. `has_key=1111` as an int) — and
concluded it is out of scope: it is not in the issue or any test, JSON object keys are
strings, `HasKeys`/`HasAnyKeys` and `KeyTransform.__init__` already coerce to `str`, and the
old code never supported it either. Adding `str()` would be speculative and would diverge
from the surrounding `compile_json_path` idiom. Decision: leave as-is, recorded in F8.

### D4 — Add an explanatory comment to `HasKeyOrArrayIndex` (the only V2 code edit)
Traces to **F13**. The class is correct but its purpose is non-obvious (why it exists and
why it overrides `compile_json_path_final_key` back to array-aware behavior). The file
already documents comparable non-obvious helpers (`CaseInsensitiveMixin`,
`KeyTransformTextLookupMixin`, the `KeyTransformIsNull` "same as has_key" comment), so a
short comment is consistent with convention and aids future maintenance. This is a
comment-only change with no effect on generated SQL (re-confirms F4).

### D5 — Make no change for the PostgreSQL path
Traces to **F11**. `as_postgresql` does not use `as_sql`/`compile_json_path*` and already
worked per the issue; nothing to do.

### D6 — Make no change for the cross-backend templates (sqlite/mysql/oracle)
Traces to **F1, F10**. The fix lives in the shared `as_sql`, so all three backends are
fixed at once (F1), and the Oracle `%`-escaping flow is unchanged because integer keys carry
no `%` and non-integer keys reproduce the original `json.dumps` output exactly (F10). No
per-backend edit needed.

## Net diff vs V1
- `repo/django/db/models/fields/json.py`: added a 3-line explanatory comment above
  `HasKeyOrArrayIndex.compile_json_path_final_key` (D4 / F13).
- No other source changes. All V1 behavior is retained.

## Confidence
High. The behavioral guarantees rest on a string-identity argument:
`compile_json_path(nav,False)+compile_json_path([final],False) ==
compile_json_path(nav+[final],False)` (used in F2 and F4), and the only intended divergence
is integer final keys for the public `has_key`/`has_keys`/`has_any_keys` lookups — exactly
the issue. (No tests were run; this is a written behavioral analysis as required.)
