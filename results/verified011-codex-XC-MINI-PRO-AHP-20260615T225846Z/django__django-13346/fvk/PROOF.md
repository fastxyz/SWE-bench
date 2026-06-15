# Constructed Proof

Status: constructed, not machine-checked.

## Claims proved

The proof covers SQL compilation shape for `KeyTransformIn`:

- MySQL direct literal RHS elements are converted to JSON-domain RHS expressions with one bind param.
- SQLite direct literal RHS elements are converted to typed JSON-domain RHS expressions with one bind param, except prepared JSON null keeps the exact-lookup null placeholder behavior.
- Oracle direct literal RHS elements select `JSON_VALUE` or `JSON_QUERY` according to the decoded JSON value and use quote-safe JSON object literals.
- Native JSON and expression RHS paths preserve inherited behavior.
- Oracle large direct-literal lists with inline RHS fragments split by RHS fragment count, not RHS param count.

## Symbolic proof sketch

### PO1

`KeyTransform.register_lookup(KeyTransformIn)` installs the lookup class for `lookup_name == 'in'` on `KeyTransform`. Django lookup resolution checks transform-specific registrations before the output field's generic lookup registration, so `value__key__in` reaches `KeyTransformIn`.

### PO2 and PO3

For direct literal params, inherited `FieldGetDbPrepValueIterableMixin.batch_process_rhs()` calls `resolve_expression_parameter()` once per prepared value. V2 first delegates to `super()`, preserving expression compilation if present. For non-expression params on non-native JSON backends:

- MySQL rewrites the SQL fragment to `JSON_EXTRACT(%s, '$')` and leaves params unchanged.
- SQLite rewrites non-`null` SQL fragments to `JSON_EXTRACT(%s, '$')` and leaves params unchanged.

These are the same RHS wrappers used by the existing exact lookup path for the same backend comparison domain.

### PO4 and PO5

For Oracle direct literal params, V2 decodes the prepared JSON value and chooses the same function family as exact lookup: `JSON_QUERY` for JSON arrays/objects, `JSON_VALUE` otherwise. The literal is constructed by `_json_value_literal(value)`, so every SQL single quote in the JSON document is doubled before the value is embedded in the SQL literal.

This discharges the Oracle string family, including strings containing apostrophes, at the SQL compilation layer.

### PO6

Oracle RHS adaptation can produce inline SQL fragments with zero bind params. The inherited splitter's loop variant is `offset` over `len(rhs_params)`, which is zero in this case and therefore cannot cover any RHS SQL fragment. V2 changes only this case:

- Let `N = len(rhs)` and `M = max_in_list_size`.
- Loop invariant after offset `K`: chunks already emitted cover exactly RHS indices `[0, K)`, each chunk length is at most `M`, and `params` contains one copy of `lhs_params` for each emitted chunk.
- Step: append one chunk for `[K, min(K + M, N))`, append one copy of `lhs_params`, and advance to `K + M`.
- Exit: `K >= N`, so every RHS fragment appears in exactly one chunk and chunks are joined by `OR`.

This restores the generic `IN` split contract for the zero-RHS-param Oracle adaptation shape.

### PO7

All non-target paths delegate:

- native JSON and expression params return the inherited `super()` result;
- non-Oracle split behavior calls the inherited splitter;
- Oracle split with RHS params calls the inherited splitter;
- `None` removal, empty-list handling, and subquery handling remain in inherited `In.process_rhs()`.

## Machine-check commands

These commands were not executed:

```sh
kompile fvk/mini-django-json-lookup.k --backend haskell
kast --backend haskell fvk/json-key-transform-in-spec.k
kprove fvk/json-key-transform-in-spec.k
```

Expected machine-check result after a future run: `kprove` discharges the claims to `#Top`, modulo the abstraction that SQL fragments are symbolic constructors rather than executable database SQL.

## Test recommendation

No test files were edited. After machine-checking and normal Django test execution in an environment that supports the relevant databases, in-domain point tests for MySQL/SQLite single-element numeric values and Oracle string values would be subsumed by the proof at the SQL compilation-shape level. Integration tests against actual databases should be kept because this proof does not model database execution.
