# Code review — V1 fix for django__django-15503

Scope reviewed: `repo/django/db/models/fields/json.py` (the only file changed in V1).
V1 changes:
- Added `HasKeyLookup.compile_json_path_final_key()` (object-key access via `json.dumps`).
- `HasKeyLookup.as_sql()` now compiles the *navigation* part of the rhs with
  `compile_json_path()` (array-index aware) and the *final* key with
  `compile_json_path_final_key()` (always an object key).
- Added `HasKeyOrArrayIndex(HasKey)` overriding `compile_json_path_final_key()` back
  to the original array-aware `compile_json_path([key], include_root=False)`.
- `KeyTransformIsNull.as_oracle`, `KeyTransformIsNull.as_sqlite`, and
  `KeyTransformExact.as_oracle` now use `HasKeyOrArrayIndex` instead of `HasKey`.

Each finding is numbered; severity in brackets.

## F1 [correctness — PASS] Reported bug is fixed
`data__has_key='1111'` against `{'1111': 'bar'}`: `rhs=['1111']`, the `else` branch
sets `rhs_key_transforms=['1111']`, then `*nav, final = ['1111']` → `nav=[]`,
`final='1111'`. `compile_json_path([], include_root=False)=''` and
`compile_json_path_final_key('1111')='.'+json.dumps('1111')='."1111"'`, with
`lhs_json_path='$'` → path `$."1111"`. SQL becomes
`JSON_TYPE(data,'$."1111"') IS NOT NULL` (SQLite),
`JSON_CONTAINS_PATH(data,'one','$."1111"')` (MySQL),
`JSON_EXISTS(data,'$."1111"')` (Oracle) — all now match the object key. The non-bug
assertion (`has_key='foo'`) is unchanged. Correct.

## F2 [regression — PASS] Existing has_key/has_keys/has_any_keys SQL is byte-identical for non-numeric final keys
For any non-integer final key, `compile_json_path_final_key(k)` returns
`"."+json.dumps(k)`, which is exactly the non-integer branch of the original
`compile_json_path`. Verified equal output for every existing case:
`test_has_key` (`$."a"`), `test_has_key_deep` (`$."baz"."c"`, `$."baz"."a"`,
`$."d"[1]."f"`), `test_has_key_list` (`$[1]."b"`), `test_has_keys`/`test_has_any_keys`
(lists of non-numeric keys), and `test_lookups_with_key_transform`. Only an *integer*
final key changes output — which is precisely the bug. No regression.

## F3 [regression — PASS] Navigation keeps array-index semantics
The integer in `value__1__has_key="b"` (column is a JSON list) and `value__d__1__has_key="f"`
(`d` is a JSON array) is part of the *lhs* path (`lhs_json_path`) or the *navigation*
prefix of the rhs (`rhs_key_transforms[:-1]`), both still compiled by `compile_json_path`.
They remain `$[1]."b"` and `$."d"[1]."f"`. A blanket "no array paths" change would have
broken these; the navigation-vs-final split avoids that. Correct.

## F4 [regression — PASS] Internal HasKey reuse (isnull / exact-null) is byte-identical
`KeyTransformIsNull` and `KeyTransformExact.as_oracle` reuse the existence check for an
*extraction* key (`self.lhs.key_name`), where an integer legitimately means an array
index (e.g. `value__d__0__isnull`, heavily used as a base queryset). These now use
`HasKeyOrArrayIndex`, whose `compile_json_path_final_key` is
`compile_json_path([key], include_root=False)`. Because
`compile_json_path(nav,False) + compile_json_path([final],False)
 == compile_json_path(nav+[final],False)`, `HasKeyOrArrayIndex.as_sql` produces exactly
the SQL the old `HasKey.as_sql` produced. Verified for `value__d__0__isnull` (`$."d"[0]`)
and `value__a__isnull` (`$."a"`). Zero behavioral change for these callers — so the many
tests built on `value__d__0__isnull=False` are preserved.

## F5 [completeness — PASS] All internal HasKey() constructions were migrated
`grep HasKey(` in the file shows exactly three call sites, all passing `self.lhs.key_name`
(extraction keys): `KeyTransformIsNull.as_oracle`, `KeyTransformIsNull.as_sqlite`,
`KeyTransformExact.as_oracle`. All three were switched to `HasKeyOrArrayIndex`. No
extraction-key existence check was left on the object-key path.

## F6 [improvement] Negative / leading-zero numeric keys now correct
`has_key='-1'` and `has_key='007'`: old `compile_json_path` did `int()` → `[-1]` / `[7]`
(array index, wrong, and `[7]` silently mis-normalizes `'007'`). New code →
`$."-1"` / `$."007"` (object keys). This is consistent with the issue (any numeric-looking
string key) and with PostgreSQL. Improvement, no downside.

## F7 [improvement] Numeric-string key against a JSON array now matches PostgreSQL
`has_key='1'` on a JSON array column: PostgreSQL `?` returns false (string '1' is not an
element); old SQLite path `$[1]` returned true (element at index 1 exists) — an
inconsistency. New path `$."1"` → no object key → false, matching PostgreSQL. Improvement.
(The separate, pre-existing PostgreSQL "string is an array element" semantics for
*non-numeric* keys is unchanged and out of scope.)

## F8 [edge case — analyzed, acceptable / out of scope] Raw non-string passed to has_key
`HasKey` has `prepare_rhs=False` and no `str()` coercion, so `has_key=1111` (a raw int)
reaches `compile_json_path_final_key` as an int; `json.dumps(1111)='1111'` → path
`$.1111` (unquoted). On MySQL an unquoted numeric member is invalid and would error; on
SQLite it may or may not resolve. Assessment:
- This input is not part of the issue, not in any test, and unusual: JSON object keys are
  strings, the docs use string keys, and values loaded from the DB are strings.
- `HasKeys`/`HasAnyKeys` already coerce items with `str()`, and `KeyTransform.__init__`
  coerces `key_name` with `str()`, so every realistic path yields a string final key.
- The old code also mishandled this input (treated it as array index `[1111]`), so it was
  never supported.
Decision: keep `json.dumps(key_transform)` to mirror `compile_json_path`'s established
idiom exactly (F2 relies on this equivalence). Coercing here would be speculative scope
creep for an unsupported input. Recorded, not changed. See control_notes.

## F9 [robustness — PASS] Iterable unpacking `*nav, final = rhs_key_transforms` is always safe
`rhs_key_transforms` is never empty: the `else` branch sets `[key]` (len 1), and
`KeyTransform.preprocess_lhs` starts from `[self.key_name]` and only inserts, so len ≥ 1.
The unpack therefore always binds `final_key` and never raises `ValueError`.

## F10 [error handling / Oracle escaping — PASS] %-escaping behavior unchanged
On Oracle, paths are inlined via `sql % tuple(params)` (one `%` pass over the format
string). For final keys originating from a `KeyTransform` rhs, `preprocess_lhs` still
doubles `%`→`%%`; `json.dumps` of an already-escaped key yields the same `."..%%.."` the
old `compile_json_path` produced, so the single `%` pass collapses it identically. For a
plain-string final key, the value is substituted (not re-scanned), identical to before.
Integer keys (the fix target) contain no `%`. No new escaping behavior introduced.

## F11 [interactions — PASS] PostgreSQL path untouched
`HasKeyLookup.as_postgresql` uses the `?`/`?&`/`?|` operators and does not call `as_sql`
or `compile_json_path*`; it already worked per the issue. `HasKeyOrArrayIndex` is only
invoked from `as_oracle`/`as_sqlite` code paths (PostgreSQL `KeyTransformIsNull` uses the
base `lookups.IsNull`), so its inherited `as_postgresql` is never reached. Unaffected.

## F12 [API / surface — PASS] No external dependents; helper is not registered
`HasKeyLookup`/`HasKey`/`HasKeys`/`HasAnyKeys`/`HasKeyOrArrayIndex` are defined and used
only within `json.py` (no other module imports them; postgres `hstore` has its own
separate `HasKey`/`HasKeys` in `contrib/postgres/lookups.py`). `HasKeyOrArrayIndex` is
intentionally **not** registered via `JSONField.register_lookup`, so it adds no
user-facing lookup and cannot shadow `has_key`. It inherits `lookup_name="has_key"` but
that is inert when unregistered.

## F13 [consistency / maintainability — minor, will improve] `HasKeyOrArrayIndex` is undocumented
The class is correct but its existence is subtle: a reader needs to know it exists to
preserve array-index semantics for *extraction* keys reused by `isnull`/exact-null, in
contrast to the user-facing `has_key*` lookups. The file documents other non-obvious
helpers (`CaseInsensitiveMixin`, `KeyTransformTextLookupMixin`, the `KeyTransformIsNull`
comment) with a short docstring/comment. Adding one brief comment here improves
maintainability and matches convention. Minimal refactor applied (see control_notes).

## Overall
V1 is correct for the issue and free of regressions (F1–F12). One minimal,
documentation-only refactor is applied for clarity (F13). One edge case (F8) is
consciously left as-is with rationale.
