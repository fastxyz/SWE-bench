# Proof Obligations

Status: constructed, not machine-checked.

## PO1 - Dispatch

`KeyTransform.register_lookup(KeyTransformIn)` must make `value__key__in=rhs` resolve to `KeyTransformIn` for key transforms.

Evidence: E1, E2.

Discharge: source registration added after `KeyTransformExact`.

## PO2 - MySQL direct literal parity

For every direct literal prepared parameter `P`, MySQL RHS adaptation must produce `JSON_EXTRACT(%s, '$')` with params `[P]`.

Evidence: E1, E2, E3, E5.

Discharge: `KeyTransformIn.resolve_expression_parameter()` sets this fragment for `connection.vendor == 'mysql'`.

## PO3 - SQLite direct literal parity

For every direct literal prepared parameter `P != 'null'`, SQLite RHS adaptation must produce `JSON_EXTRACT(%s, '$')` with params `[P]`. For `P == 'null'`, it must preserve `%s`.

Evidence: E1, E2, E3, E5.

Discharge: `KeyTransformIn.resolve_expression_parameter()` mirrors the existing `KeyTransformExact` SQLite branch.

## PO4 - Oracle direct literal parity

For every direct literal prepared parameter `P`, Oracle RHS adaptation must parse `V = json.loads(P)` and select `JSON_QUERY` for arrays/objects and `JSON_VALUE` otherwise.

Evidence: E1, E2, E4, E5.

Discharge: `KeyTransformIn.resolve_expression_parameter()` mirrors `KeyTransformExact` function selection.

## PO5 - Oracle quote-safe string literals

For every Oracle scalar/string value `V`, the SQL literal passed to `JSON_VALUE` or `JSON_QUERY` must double SQL single quotes after JSON serialization.

Evidence: E4 and default ORM validity/safety assumption I7.

Discharge: `_json_value_literal()` centralizes `json.dumps({'value': V}).replace("'", "''")`; both `KeyTransformExact` and `KeyTransformIn` use it.

## PO6 - Oracle max-list split with inline RHS fragments

If Oracle RHS adaptation returns `N` inline SQL fragments and zero RHS bind params, and `N > connection.ops.max_in_list_size()`, splitting must iterate over `N` fragments, not zero params.

Evidence: E6.

Discharge: `KeyTransformIn.split_parameter_list_as_sql()` has an Oracle branch that chunks by `len(rhs)` when `rhs_params` is empty.

## PO7 - Generic `In` frame conditions

The fix must preserve generic `In` behavior for `None` removal, empty effective RHS, subqueries, expression params, native JSON backends, and non-Oracle split behavior.

Evidence: E6 and I3.

Discharge: `KeyTransformIn` only overrides per-parameter adaptation and the Oracle zero-param split case; it delegates expression/native/non-Oracle split cases to inherited behavior.

## PO8 - Partial correctness and execution caveat

The proof is a constructed partial-correctness proof over SQL compilation shape. It is not machine-checked and does not prove database execution semantics.

Evidence: FVK honesty gate and task no-execution constraint.

Discharge: artifacts include commands but they were not executed.
