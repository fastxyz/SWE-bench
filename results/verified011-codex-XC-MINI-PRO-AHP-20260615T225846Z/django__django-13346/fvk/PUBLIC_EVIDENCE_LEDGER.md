# Public Evidence Ledger

Status: constructed from allowed files only.

## E1 - Issue title

Source: prompt/problem statement.

Quoted evidence: "On MySQL, Oracle, and SQLite, __in lookup doesn't work on key transforms."

Semantic obligation: `KeyTransform` must have a backend-aware `__in` lookup on MySQL, Oracle, and SQLite.

Status: encoded in SPEC.md, PROOF_OBLIGATIONS.md, and `json-key-transform-in-spec.k`.

## E2 - Parity with exact lookup

Source: prompt/problem statement.

Quoted evidence: "`our_field__key__in': [0]` returns 0 rows, while `our_field__key': 0` returns 312 rows. `I would expect that both filters would give me the same queryset`."

Semantic obligation: for direct literal values, single-value `__in` must be equivalent to exact lookup on the same key and value.

Status: encoded as the primary postcondition.

## E3 - Single-element boundary

Source: public hints in problem statement.

Quoted evidence: "this error only occurs if the length of the list, where __in is used, only contains one element."

Semantic obligation: list cardinality 1 is an explicit boundary case and cannot be dismissed as an implementation edge case.

Status: encoded in proof obligations for RHS adaptation per element.

## E4 - Oracle strings

Source: public hints in problem statement.

Quoted evidence: "On Oracle, it doesn't work when list contains strings."

Semantic obligation: Oracle RHS string literals must be adapted through `JSON_VALUE` with valid string literal construction.

Status: encoded in proof obligations PO4 and PO5.

## E5 - Existing exact lookup pattern

Source: implementation evidence, `repo/django/db/models/fields/json.py`.

Quoted evidence: `KeyTransformExact.process_rhs()` wraps MySQL RHS with `JSON_EXTRACT`, SQLite RHS with `JSON_EXTRACT`, and Oracle RHS with `JSON_VALUE` or `JSON_QUERY`.

Semantic obligation: not intent by itself, but it supplies the local equivalence pattern required by E2.

Status: used in proof obligations for exact-vs-in parity.

## E6 - Generic `In` list mechanics

Source: implementation evidence, `repo/django/db/models/lookups.py`.

Quoted evidence: generic `In.process_rhs()` removes `None`, calls `batch_process_rhs()`, and `split_parameter_list_as_sql()` chunks by backend max list size.

Semantic obligation: a targeted JSON key-transform fix must preserve these mechanics unless public intent requires changing them.

Status: encoded as frame condition PO7 and Oracle split obligation PO6.
