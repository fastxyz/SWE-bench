# PROOF

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`,
Python, or Django tests were run.

## Claims Proved Constructively

The proof covers the abstract identifier-flow model in
`mini-django-upsert.k` and `django-bulk-create-conflict-spec.k`.

1. If `on_conflict == update`, resolving `update_fields` and `unique_fields`
   through the model field map produces `Field` objects whose `column` values
   are the database identifiers required by the issue.
2. If `on_conflict == update`, the compiler sends exactly those column values to
   backend conflict SQL generation.
3. If `on_conflict != update`, the newly added conversion does not inspect or
   resolve otherwise unused conflict option values.
4. Materializing column values as lists preserves a list-like backend hook
   argument shape while satisfying the column-name contract.

## Symbolic Proof Sketch

Let `FM` be the model field map, where a model field name maps to a field record
`field(name, column)`. For the issue example:

```text
FM["blacklistid"] = field("blacklistid", "BlacklistID")
FM["sectorid"] = field("sectorid", "SectorID")
```

For `OnConflict.UPDATE`, V2 executes the guarded conversion:

```text
update_fields := resolve(FM, ["sectorid"])
unique_fields := resolve(FM, ["blacklistid"])
```

By `Field.get_attname_column()`, each resolved field carries
`column = db_column or attname`, so the symbolic state becomes:

```text
update_fields = [field("sectorid", "SectorID")]
unique_fields = [field("blacklistid", "BlacklistID")]
```

The compiler then applies the column projection:

```text
update_columns = ["SectorID"]
unique_columns = ["BlacklistID"]
```

Those are the values passed to `on_conflict_suffix_sql()`. The PostgreSQL and
SQLite implementations quote `unique_columns` for the conflict target and quote
`update_columns` for `field = EXCLUDED.field`; MySQL/MariaDB quote
`update_columns` for `ON DUPLICATE KEY UPDATE`. Therefore the modeled issue
input cannot produce `"blacklistid"` or `"sectorid"` in conflict SQL unless the
model's actual `Field.column` values are those strings.

For `on_conflict != update`, V2 follows the else branch in the compiler and the
guard in `bulk_create()` is false. Therefore no new `opts.get_field()` call is
introduced for non-upsert conflict-option values.

## Adequacy Check

The English meaning of the K claims is listed in `FORMAL_SPEC_ENGLISH.md` and
audited against `INTENT_SPEC.md` in `SPEC_AUDIT.md`. The claims are adequate for
the issue because they model the exact observable that failed: field names being
used where database column identifiers were required in conflict SQL.

## Machine-Check Commands Not Run

These are the commands a human would run in an environment with K installed:

```sh
kompile fvk/mini-django-upsert.k --main-module MINI-DJANGO-UPSERT --syntax-module MINI-DJANGO-UPSERT-SYNTAX --backend haskell
kast --definition mini-django-upsert-kompiled fvk/django-bulk-create-conflict-spec.k
kprove fvk/django-bulk-create-conflict-spec.k --definition mini-django-upsert-kompiled
```

Expected result: `#Top` for the claims in
`django-bulk-create-conflict-spec.k`.

## Test Redundancy Recommendation

No tests are recommended for removal. The proof is constructed, not
machine-checked, and this task forbids running or modifying tests. Existing
tests around upsert conflicts, `unique_fields=["pk"]`, backend behavior, and
custom columns should remain.

## Residual Risk

The proof abstracts away full Python execution, Django transactions, database
driver behavior, and backend SQL parser behavior. It proves the identifier flow
at the source level under the stated assumptions. Hidden or public integration
tests remain necessary to cover execution details not represented in the mini
semantics.
