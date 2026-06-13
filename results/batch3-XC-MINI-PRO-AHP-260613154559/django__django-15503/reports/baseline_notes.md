# Baseline notes — django__django-15503

## Issue

`has_key`, `has_keys`, and `has_any_keys` lookups on `models.JSONField()` fail to
find **numeric** keys (e.g. `data__has_key='1111'` against `{'1111': 'bar'}`) on
SQLite, MySQL, and Oracle. The same query works on PostgreSQL.

## Root cause

All three lookups are implemented by `HasKeyLookup.as_sql()` in
`django/db/models/fields/json.py`. To build the JSON path of the key being
checked, it called `compile_json_path(rhs_key_transforms, include_root=False)`.

`compile_json_path()` interprets any path component that parses as an integer as
an **array index** (`[1111]`) rather than an **object key** (`."1111"`):

```python
try:
    num = int(key_transform)
except ValueError:        # non-integer -> object key  ."foo"
    path.append(".")
    path.append(json.dumps(key_transform))
else:                     # integer    -> array index  [num]
    path.append("[%s]" % num)
```

So `data__has_key='1111'` produced the path `$[1111]` and the generated SQL
(`JSON_TYPE(data, '$[1111]') IS NOT NULL` on SQLite, `JSON_CONTAINS_PATH` on
MySQL, `JSON_EXISTS` on Oracle) looked for array element 1111 and never matched
the object key `"1111"`. PostgreSQL was unaffected because `as_postgresql()`
uses the `?`/`?&`/`?|` operators with the key passed as a string, which always
means an object key.

A `has_key` always tests for an **object key** (keys in a JSON object are
strings), so the key being checked must never be compiled as an array index.

## Fix

`django/db/models/fields/json.py` only.

1. **`HasKeyLookup.compile_json_path_final_key()` (new) + `as_sql()` change.**
   The *final* component of the path — i.e. the key whose existence is being
   tested — is now compiled with a dedicated helper that always emits
   object-key access:

   ```python
   def compile_json_path_final_key(self, key_transform):
       # Compile the final key without interpreting ints as array elements.
       return ".%s" % json.dumps(key_transform)
   ```

   `as_sql()` now splits the right-hand-side path into navigation segments and
   the final key:

   ```python
   *rhs_key_transforms, final_key = rhs_key_transforms
   rhs_json_path = compile_json_path(rhs_key_transforms, include_root=False)
   rhs_json_path += self.compile_json_path_final_key(final_key)
   ```

   Navigation segments still go through `compile_json_path()` (so integers there
   are still array indices), but the key being looked up is always an object
   key. `json.dumps('1111')` -> `"1111"`, giving the path `$."1111"`, which is
   valid on SQLite/MySQL/Oracle (the existing non-numeric case already relied on
   this `$."key"` form).

   Keeping array indices for *navigation* is required: e.g.
   `value__d__1__has_key="f"` (where `d` is a JSON array) must compile to
   `$."d"[1]."f"`, and `value__1__has_key="b"` (where the column is a JSON list)
   must compile to `$[1]."b"`. These are exercised by `test_has_key_deep` and
   `test_has_key_list`.

2. **`HasKeyOrArrayIndex(HasKey)` (new).** Some code reuses `HasKey` internally
   to test for the existence of a *key-transform/extraction* key rather than a
   user-supplied `has_key` argument. For those, a numeric key legitimately means
   an array index (e.g. `value__d__0__isnull`, where `d[0]` is array element 0).
   This subclass restores the original behaviour for the final key:

   ```python
   class HasKeyOrArrayIndex(HasKey):
       def compile_json_path_final_key(self, key_transform):
           return compile_json_path([key_transform], include_root=False)
   ```

   Because `compile_json_path(nav, False) + compile_json_path([final], False)`
   equals `compile_json_path(nav + [final], False)`, `HasKeyOrArrayIndex.as_sql()`
   produces exactly the same SQL the old `HasKey.as_sql()` produced — i.e. zero
   behavioural change for these internal callers.

3. **Switched the three internal `HasKey(...)` uses to `HasKeyOrArrayIndex(...)`:**
   - `KeyTransformIsNull.as_oracle`
   - `KeyTransformIsNull.as_sqlite`
   - `KeyTransformExact.as_oracle` (the "field has key and it's NULL" branch)

   All three pass `self.lhs.key_name` (an extraction key), so they must retain
   array-index semantics for numeric keys. Without this, `value__d__0__isnull`
   (heavily used as a base queryset in the test module) and similar would break.

## Why this split (and not a blanket change)

`compile_json_path()` is shared with `KeyTransform.as_mysql/as_oracle/as_sqlite`
(value extraction), where integer-as-array-index is correct and expected, so it
was left untouched. The only thing that is semantically always an object key is
the *final* key of a `has_key`/`has_keys`/`has_any_keys` test; that is the only
place changed to object-key access.

## Backends

The fix lives in the shared `HasKeyLookup.as_sql()`, which is the implementation
used by `as_sqlite` (`JSON_TYPE ... IS NOT NULL`), `as_mysql`
(`JSON_CONTAINS_PATH`), and `as_oracle` (`JSON_EXISTS`), so all three affected
backends are fixed at once. `as_postgresql()` does not use `as_sql()` /
`compile_json_path()` and already worked, so it is unchanged.

## Alternatives considered and rejected

- **Change `compile_json_path()` itself to never emit array indices.** Rejected:
  it would break JSON value extraction and array navigation
  (`value__d__1__has_key`, `value__1__has_key`, `value__d__0__isnull`), all of
  which have existing tests.
- **Make the final key object-access for *all* `HasKey` instances (including the
  internal isnull/exact callers).** Rejected: breaks `value__d__0__isnull` etc.,
  where a numeric extraction key must remain an array index. Hence the
  `HasKeyOrArrayIndex` subclass to keep those callers identical to before.
- **`str()`-coercing the final key before `json.dumps()`.** Not done, to mirror
  `compile_json_path()`'s existing `json.dumps(key_transform)` style; in practice
  `has_key` keys are strings (JSON object keys are strings, and `has_keys`/
  `has_any_keys` already coerce their items with `str()`).

## Assumptions

- SQLite/MySQL/Oracle accept the quoted member form `$."1111"`. This is the same
  form already produced for non-numeric keys (`$."foo"`) by the pre-existing
  code, which the current passing `has_key` tests rely on.
- The existing tests in `tests/model_fields/test_jsonfield.py`
  (`test_has_key_deep`, `test_has_key_list`, `test_isnull_key`, the many
  `value__d__0__isnull=False` base querysets, `test_key_escape`) represent
  intended behaviour and must continue to pass; the fix was designed to preserve
  all of them while fixing numeric `has_key`/`has_keys`/`has_any_keys`.
