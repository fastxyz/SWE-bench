# Public Evidence Ledger

## E-001

Source: prompt / issue.

Quoted evidence: "has_key, has_keys, and has_any_keys JSONField() lookups don't
handle numeric keys on SQLite, MySQL, and Oracle."

Semantic obligation: numeric-looking lookup arguments for these three lookups
must be object keys on SQLite, MySQL, and Oracle.

Status: encoded by PO-001 and PO-003.

## E-002

Source: prompt / issue reproduction.

Quoted evidence: `JsonFieldHasKeyTest(data={'1111': 'bar'})` followed by
`filter(data__has_key='1111')` should find one row.

Semantic obligation: the generated path for the final lookup segment `"1111"`
must select object member `"1111"` and not array index `[1111]`.

Status: encoded by PO-001.

## E-003

Source: public hint.

Quoted evidence: "has_key, has_keys, and has_any_keys lookups uses
compile_json_path() on SQLite, MySQL, and Oracle which uses array paths for
integers. We shouldn't use array paths for these lookups."

Semantic obligation: path-based backends must use different compilation for the
right-hand lookup key than ordinary `compile_json_path()`.

Status: encoded by PO-001 and PO-003.

## E-004

Source: docs, `repo/docs/topics/db/queries.txt`.

Quoted evidence: "`has_key` Returns objects where the given key is in the
top-level of the data"; "`has_keys` Returns objects where all of the given keys
are in the top-level of the data"; "`has_any_keys` Returns objects where any of
the given keys are in the top-level of the data."

Semantic obligation: the lookup argument is semantically a key, not a positional
array component.

Status: encoded by PO-001 and PO-003.

## E-005

Source: public tests, `repo/tests/model_fields/test_jsonfield.py`.

Quoted evidence: `Q(value__d__1__has_key="f")` and `Q(value__1__has_key="b")`
are expected to match nested list items.

Semantic obligation: numeric transform segments that occur before the final
existence-tested key must continue to compile as array indexes.

Status: encoded by PO-002.

## E-006

Source: public tests and source comment.

Quoted evidence: source comment: `key__isnull=False is the same as
has_key='key'`; tests include `value__d__0__isnull=False`.

Semantic obligation: internal existence checks used for `KeyTransform` paths
must preserve normal transform compilation, including numeric final transform
segments as array indexes.

Status: encoded by PO-004. This is the V1 regression finding.

## E-007

Source: implementation.

Quoted evidence: `HasKeyLookup.as_postgresql()` uses PostgreSQL key operators;
the issue says PostgreSQL worked as expected.

Semantic obligation: PostgreSQL-specific logic should remain unchanged.

Status: encoded by PO-006.
