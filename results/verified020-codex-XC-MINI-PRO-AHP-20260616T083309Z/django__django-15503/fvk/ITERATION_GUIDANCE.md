# Iteration Guidance

## Code decision

Do not keep V1 unchanged. FVK Finding F-002 shows that V1 over-applied
object-member final-key semantics to internal `KeyTransform` existence checks.

Keep the V1 helper for actual `has_key`-style RHS keys, but gate it behind a
defaulted `final_key=True` argument. Internal transform-existence callers must
pass `final_key=False`.

## Applied V2 changes

- `HasKeyLookup.as_sql()` now accepts `final_key=True`.
- `HasKeyLookup.as_oracle()` forwards the same flag.
- `KeyTransformIsNull.as_oracle()` passes `final_key=False`.
- `KeyTransformIsNull.as_sqlite()` passes `final_key=False`.
- `KeyTransformExact.as_oracle()` passes `final_key=False` for its internal
  JSON-null existence check.

## Suggested future tests

Do not edit tests in this benchmark. If tests were allowed, add coverage for:

- `data__has_key="1111"` on SQLite, MySQL, and Oracle;
- `data__has_keys=["1111"]`;
- `data__has_any_keys=["1111"]`;
- `value__d__0__isnull=False` to guard the V1 regression;
- Oracle JSON-null exact lookup on a numeric array index path.

## Future verification

Run the commands recorded in `PROOF.md` in an environment with K installed. Keep
all tests until `kprove` returns `#Top` and backend integration coverage has
been reviewed.
