# FORMAL_SPEC_ENGLISH

Status: constructed, not machine-checked.

## Claim: reverse-old-fields-restores-generated-name

If migration is allowed and a `RenameIndex(old_fields=FIELDS, new_name=NEW)`
operation is applied backwards from a database state containing index name
`NEW`, the resulting database state contains the generated old index name for
the target table and fields.

## Claim: reverse-old-fields-skipped-when-migration-disallowed

If migration is not allowed for the target model, applying the same backwards
operation leaves the database index name unchanged.

## Claim: round-trip-reapply-safe

For distinct `NEW` and generated old names, the sequence forwards, backwards,
forwards maps:

`GENERATED -> NEW -> GENERATED -> NEW`

Therefore the final forwards step does not start from a database state where the
matching index is already named `NEW`.

## Frame condition: named-index branch

The formal claims do not change or re-specify the `old_name` branch of
`RenameIndex`; the audit is limited to `old_fields`.
