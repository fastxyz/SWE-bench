# Constructed Proof

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Claims Proved in the Model

The compact model in `mini-schema-editor.k` defines:

* `shouldAlter(base, old, new)`: compares quoted column, path, args,
  database-relevant kwargs, and `choices`.
* `shouldAlter(sqlite, old, new)`: compares quoted column, path, args, and
  database-relevant kwargs, but ignores `choices`.

The spec file `schema-editor-spec.k` states four claims:

* `BASE-CHOICES-STILL-ALTERS`: base behavior returns true for choices-only
  differences.
* `SQLITE-CHOICES-NOOP`: SQLite returns false for choices-only differences.
* `SQLITE-SCHEMA-ATTR-STILL-ALTERS`: SQLite returns true when any
  database-relevant deconstruction component differs.
* `SQLITE-COLUMN-STILL-ALTERS`: SQLite returns true when the quoted column
  differs.

## Proof Sketch

For `BASE-CHOICES-STILL-ALTERS`, symbolic execution rewrites
`shouldAlter(base, OLD, NEW)` to `notBool sameIncludingChoices(OLD, NEW)`.
Given equal quoted column, path, args, and database-relevant kwargs but distinct
choices, the `sameIncludingChoices` fallback rule yields `false`, so the result
is `true`.

For `SQLITE-CHOICES-NOOP`, symbolic execution rewrites
`shouldAlter(sqlite, OLD, NEW)` to `notBool sameDbRelevant(OLD, NEW)`. Equal
quoted column, path, args, and database-relevant kwargs match the positive
`sameDbRelevant` rule even when choices differ, so the result is `false`.

For `SQLITE-SCHEMA-ATTR-STILL-ALTERS`, the same SQLite rewrite applies, but a
database-relevant kwarg difference prevents the positive `sameDbRelevant` rule
from matching. The fallback yields `false`, so `shouldAlter(sqlite, ...)`
returns `true`.

For `SQLITE-COLUMN-STILL-ALTERS`, the quoted column difference likewise prevents
the positive `sameDbRelevant` rule from matching. The fallback yields `false`,
so `shouldAlter(sqlite, ...)` returns `true`.

There are no loops or recursive calls in the modeled decision, so no circularity
claim is required. The proof is partial correctness over the modeled decision
function.

## Source Correspondence

The model's `base` branch corresponds to
`BaseDatabaseSchemaEditor._field_should_be_altered()`, where the private
`_field_should_be_altered_non_database_attrs` tuple excludes `choices`.

The model's `sqlite` branch corresponds to
`django/db/backends/sqlite3/schema.py`, where
`DatabaseSchemaEditor._field_should_be_altered_non_database_attrs` extends the
base tuple with `("choices",)`.

## Adequacy and Compatibility

The claims cover the full public issue intent:

* the reported SQLite choices-only operation is no-op;
* non-choices schema changes remain alterations;
* global/base behavior does not ignore `choices`;
* V2 avoids V1's public-looking hook name.

The compatibility audit found no changed method signatures, no changed SQL
templates, and no changed public migration APIs.

## Test Recommendation

No test files were read or modified, and no tests were run. Keep all existing
tests. A future regression test for SQLite choices-only `AlterField` would be
subsumed by `SQLITE-CHOICES-NOOP` only after the emitted K commands are actually
machine-checked.

## Machine-Check Commands

These commands were not executed in this session.

```sh
kompile fvk/mini-schema-editor.k --backend haskell
kast --backend haskell fvk/schema-editor-spec.k
kprove fvk/schema-editor-spec.k
```

Expected result after a successful machine check: `#Top`.
