# Formal Spec English

Status: constructed, not machine-checked.

## C1 - MySQL literal adaptation

For a non-expression direct literal used in a JSON key-transform `IN` lookup on MySQL, the RHS SQL fragment is `JSON_EXTRACT(%s, '$')`, and the JSON-prepared parameter is preserved.

## C2 - SQLite literal adaptation

For a non-expression direct literal used in a JSON key-transform `IN` lookup on SQLite, non-`null` JSON values are compared through `JSON_EXTRACT(%s, '$')`. A prepared `null` value remains a plain placeholder, matching the existing exact-lookup null handling.

## C3 - Oracle scalar/string adaptation

For a non-expression direct literal used in a JSON key-transform `IN` lookup on Oracle, scalar JSON values, including strings, are compared through `JSON_VALUE('<quote-safe JSON object>', '$.value')`.

## C4 - Oracle array/object adaptation

For a non-expression direct literal used in a JSON key-transform `IN` lookup on Oracle, JSON arrays and objects are compared through `JSON_QUERY('<quote-safe JSON object>', '$.value')`.

## C5 - Native JSON and expression preservation

For native JSON backends and expression RHS parameters, the new lookup preserves the inherited behavior.

## C6 - Oracle large-list splitting

When Oracle direct-literal RHS adaptation produces inline RHS SQL fragments with no bind params, large `IN` lists are split by SQL fragment count rather than bind-param count. Every RHS fragment appears in exactly one chunk, LHS params are repeated once per chunk, and chunks are joined by `OR`.

## C7 - Lookup dispatch

Registering `KeyTransformIn` on `KeyTransform` makes `value__key__in` use the specialized lookup.
