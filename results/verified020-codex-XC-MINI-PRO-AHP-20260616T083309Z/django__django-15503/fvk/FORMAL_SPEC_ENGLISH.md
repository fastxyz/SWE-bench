# Formal Spec In English

The K claims in `jsonfield-has-key-spec.k` are paraphrased here.

## C-001 HAS-KEY-NUMERIC-FINAL

For an actual `has_key`-style lookup whose right-hand key is numeric-looking
`1111`, the compiled relative path component is an object member named
`"1111"`, not array index `1111`.

## C-002 PREFIX-NUMERIC-INDEX-PRESERVED

For an actual `has_key`-style lookup with prefix transforms `d, 1` and final key
`f`, the prefix compiles as object member `d` then array index `1`, and only the
final lookup component compiles as object member `f`.

## C-003 HAS-KEYS-HAS-ANY-KEYS-PER-KEY

`has_keys` and `has_any_keys` use the same per-key path construction as
`has_key`; therefore each numeric-looking item in their RHS lists compiles as an
object member.

## C-004 TRANSFORM-EXISTENCE-NUMERIC-FINAL

For internal transform-existence callers such as `key__isnull=False` and Oracle
JSON-null exact matching, the final numeric transform segment still compiles as
an array index. These callers use `final_key=False`.

## C-005 BACKEND-TEMPLATE-FRAME

The backend SQL templates and logical operators are framed: the proof only
changes the JSON path component passed into SQLite `JSON_TYPE`, MySQL
`JSON_CONTAINS_PATH`, and Oracle `JSON_EXISTS`.

## C-006 POSTGRESQL-FRAME

PostgreSQL-specific `HasKeyLookup.as_postgresql()` is outside the path-based
helper proof and remains unchanged.
