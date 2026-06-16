# Baseline Notes

## Root cause

`HasKeyLookup.as_sql()` used `compile_json_path()` for the right-hand side of
`has_key`, `has_keys`, and `has_any_keys`. That helper treats digit-like path
segments as JSON array indexes, so a lookup such as `value__has_key="1111"`
compiled the key test as `$[1111]` instead of `$."1111"` on SQLite, MySQL, and
Oracle. PostgreSQL uses dedicated key operators for these lookups, so it did not
hit this JSON path behavior.

## Changed files

`repo/django/db/models/fields/json.py`

Added `compile_json_path_final_key()` and used it when building the right-hand
JSON path for `HasKeyLookup`. The helper preserves existing array-index behavior
for intermediate transforms, but always renders the final lookup component as an
object key. This fixes numeric object keys for `has_key`, `has_keys`, and
`has_any_keys` without changing normal `KeyTransform` path compilation.

## Assumptions and rejected alternatives

I assumed the right-hand side of a `has_key`-style lookup names an object member,
even when the member name contains only digits. JSON object keys are strings, and
the issue specifically concerns numeric-looking keys such as `"1111"`.

I considered changing `compile_json_path()` itself so digit-like components were
always object keys. I rejected that because regular key transforms intentionally
use digit-like path components as array indexes on these backends, and existing
lookup patterns such as `value__d__1__has_key="f"` depend on that behavior.

I also considered changing left-hand path handling inside `HasKeyLookup`, but the
left-hand side may legitimately include array indexes before the key existence
test. The minimal fix is to special-case only the final right-hand lookup segment.
