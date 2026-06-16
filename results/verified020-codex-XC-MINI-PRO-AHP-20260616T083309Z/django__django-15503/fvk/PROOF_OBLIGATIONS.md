# Proof Obligations

Status: constructed, not machine-checked.

## PO-001: Numeric final RHS keys are object members

For any actual `has_key`-style RHS path whose final segment is numeric-looking,
`HasKeyLookup.as_sql(final_key=True)` must use `compile_json_path_final_key()`
so the final segment is rendered as an object member.

Finding link: F-001.

K claim: `HAS-KEY-NUMERIC-FINAL`.

## PO-002: Numeric transform prefixes are preserved as array indexes

For nested lookup paths, all intermediate segments before the final
existence-tested key must continue to use ordinary `compile_json_path()`
semantics. Numeric intermediate transform segments compile as array indexes.

Finding link: F-002 prevention.

K claim: `PREFIX-NUMERIC-INDEX-PRESERVED`.

## PO-003: The rule covers `has_key`, `has_keys`, and `has_any_keys`

`HasKeys` and `HasAnyKeys` inherit `HasKeyLookup.as_sql()`, so each RHS item in
their lists must use the same final-key path rule as `HasKey`.

Finding link: F-001.

K claim: `HAS-KEYS-HAS-ANY-KEYS-PER-KEY`.

## PO-004: Internal transform-existence callers opt out

`KeyTransformIsNull` and `KeyTransformExact.as_oracle` use `HasKey` to test a
`KeyTransform` path, not a user-provided `has_key` RHS. These callers must pass
`final_key=False`, causing numeric final transform segments to compile as array
indexes.

Finding link: F-002.

K claim: `TRANSFORM-EXISTENCE-NUMERIC-FINAL`.

## PO-005: SQL templates and logical operators are framed

The patch may change only the JSON path parameter/component. It must not change
SQLite `JSON_TYPE`, MySQL `JSON_CONTAINS_PATH`, Oracle `JSON_EXISTS`, lookup
names, or `AND`/`OR` composition for multi-key lookups.

Finding link: none; frame obligation.

K claim: represented as a frame condition in `FORMAL_SPEC_ENGLISH.md`.

## PO-006: PostgreSQL behavior is framed

`HasKeyLookup.as_postgresql()` must remain unchanged because the issue reports
PostgreSQL working and its implementation does not use the path helper.

Finding link: none; frame obligation.

K claim: represented as a frame condition in `FORMAL_SPEC_ENGLISH.md`.
