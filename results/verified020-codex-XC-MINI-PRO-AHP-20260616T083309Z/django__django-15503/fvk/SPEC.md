# FVK Spec

Status: constructed, not machine-checked.

## Audited unit

The audited unit is JSON path component selection for Django `JSONField`
`has_key`, `has_keys`, and `has_any_keys` on path-based backends, plus the
internal `HasKey` reuse sites that check `KeyTransform` existence.

The formal model intentionally abstracts away the full ORM compiler, SQL
database execution, and JSON value storage. It retains the property under test:
whether a numeric-looking component becomes an object member or an array index.

## Contract

For actual `has_key`-style lookup RHS values:

- non-numeric keys compile as object members;
- numeric-looking keys also compile as object members;
- intermediate transform components in a RHS `KeyTransform` retain ordinary
  transform semantics, so numeric intermediate components compile as array
  indexes;
- `has_keys` and `has_any_keys` apply the same per-key rule to each listed key.

For internal transform-existence uses:

- the caller may request ordinary transform semantics with `final_key=False`;
- numeric final transform segments compile as array indexes.

## Public intent ledger summary

- E-001/E-002: the issue requires `data__has_key="1111"` to find object key
  `"1111"` on SQLite, MySQL, and Oracle.
- E-003: the public hint identifies `compile_json_path()` converting integers
  into array paths as the root cause for all three lookup variants.
- E-004: docs describe the lookup argument as a key.
- E-005: public tests require numeric transform prefixes such as
  `value__d__1__has_key="f"` and `value__1__has_key="b"` to remain array-index
  paths.
- E-006: public tests and source comments require `KeyTransform` existence
  checks such as `value__d__0__isnull=False` to preserve transform semantics.
- E-007: PostgreSQL uses a different implementation and is framed unchanged.

The full ledger is in `PUBLIC_EVIDENCE_LEDGER.md`.

## K artifacts

- `mini-jsonpath.k`: a mini semantics for path component compilation.
- `jsonfield-has-key-spec.k`: K claims for the path obligations.

The commands to machine-check later are recorded in `PROOF.md`; they were not
run in this session.
