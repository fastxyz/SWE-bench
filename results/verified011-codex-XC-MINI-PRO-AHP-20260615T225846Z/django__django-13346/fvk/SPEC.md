# FVK Spec

Status: constructed, not machine-checked.

## Scope

The verified unit is `KeyTransformIn` in `repo/django/db/models/fields/json.py`, together with the helper `_json_value_literal()` and the lookup registration on `KeyTransform`.

The observable modeled by this FVK pass is SQL compilation shape: the RHS SQL fragment and parameter count/value shape generated for each direct JSON literal in an `IN` list. This is the behavior that determines whether the database compares a JSON-extracted LHS against a JSON-equivalent RHS.

## Intent ledger summary

- E1: MySQL, Oracle, and SQLite key-transform `__in` must work.
- E2: `key__in=[v]` must be equivalent to `key=v` for direct literal values.
- E3: single-element lists are an explicit failing boundary.
- E4: Oracle strings are explicitly in scope.
- E5: existing exact lookup backend wrappers provide the local parity pattern.
- E6: generic `In` list mechanics are preserved as frame conditions.

The full ledger is in `fvk/PUBLIC_EVIDENCE_LEDGER.md`.

## Contract

For every backend `B`, native-JSON flag `N`, direct literal prepared parameter `P`, and original JSON value `V = json.loads(P)`:

1. If `B == mysql` and native JSON is false, `resolve_expression_parameter()` returns SQL fragment `JSON_EXTRACT(%s, '$')` with the original parameter `P`.

2. If `B == sqlite` and native JSON is false, `resolve_expression_parameter()` returns `JSON_EXTRACT(%s, '$')` with parameter `P` for `P != 'null'`, and preserves `%s` for `P == 'null'`.

3. If `B == oracle` and native JSON is false, `resolve_expression_parameter()` parses `P` and returns:
   - `JSON_QUERY('<literal>', '$.value')` when `V` is a JSON object or array;
   - `JSON_VALUE('<literal>', '$.value')` otherwise.

   The `<literal>` is `_json_value_literal(V)`, which is `json.dumps({'value': V})` with SQL single quotes doubled.

4. If native JSON is true, or if `param` is an expression, the lookup delegates to the inherited generic expression/literal behavior.

5. `KeyTransform.register_lookup(KeyTransformIn)` ensures `value__key__in=...` uses this lookup instead of the generic `Field` lookup.

6. For Oracle large direct-literal lists where RHS adaptation produces inline SQL fragments and zero bind params, `split_parameter_list_as_sql()` chunks by RHS fragment count, repeats LHS params once per chunk, and joins chunks with `OR`. If RHS params are present, the method delegates to the generic splitter.

## Frame conditions

- Generic removal of `None` from `IN` lists is unchanged.
- Generic empty-list `EmptyResultSet` behavior is unchanged.
- Subquery RHS behavior is unchanged.
- Expression RHS behavior is unchanged.
- PostgreSQL/native JSON behavior is unchanged.
- MySQL and SQLite large-list splitting continues to use the inherited generic splitter.

## Mini-K model

The formal core is represented by:

- `fvk/mini-django-json-lookup.k`
- `fvk/json-key-transform-in-spec.k`

The K model abstracts SQL strings as symbolic constructors such as `mysqlJsonExtract(_)`, `sqliteJsonExtract(_)`, `oracleJsonValue(_)`, and `oracleJsonQuery(_)`. This abstraction preserves the property under verification: whether a backend receives the same JSON-domain RHS wrapper as exact lookup, and whether the RHS has zero or one bind parameter.

## Commands not run

Per task instructions, these commands were written but not executed:

```sh
kompile fvk/mini-django-json-lookup.k --backend haskell
kast --backend haskell fvk/json-key-transform-in-spec.k
kprove fvk/json-key-transform-in-spec.k
```
