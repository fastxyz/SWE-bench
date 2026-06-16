# Constructed Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`, Python, or Django tests were run.

## What is proved

For every raw table name `T`, non-empty unique column list `col(C, CS)`, and name mode covered by `_create_unique_sql()`, the V2 statement construction satisfies:

```text
stmtReferencesColumn(createUniqueV2(T, col(C, CS), mode), raw(T), C) == true
```

for `mode` in `explicitName` and `generatedName`.

The proof also records the V1 explicit-name counterexample:

```text
stmtReferencesColumn(createUniqueV1(T, col(C, CS), explicitName), raw(T), C) == false
```

## Proof sketch

`Statement.references_column()` is modeled as a fold over statement parts with boolean `or`.

`TableColumns.references_column()` is modeled by `referencesColumn(columnsPart(K, CS), QUERY_TABLE, C)`, which reduces to:

```text
tableKeyEq(K, QUERY_TABLE) and contains(C, CS)
```

For V2 explicit-name statements, `createUniqueV2` creates:

```text
stmt(refs(tablePart(raw(T)),
     refs(quotedName,
     refs(columnsPart(raw(T), col(C, CS)), .Refs))))
```

The table part and quoted-name part do not report column references. The columns part reduces to:

```text
tableKeyEq(raw(T), raw(T)) and contains(C, col(C, CS))
```

Both operands reduce to `true`, so statement-level `or` returns `true`.

For V2 generated-name statements, the generated `indexNamePart(raw(T), col(C, CS))` already returns true, and the columns part does as well. The statement-level result is true.

For V1 explicit-name statements, `createUniqueV1` creates:

```text
columnsPart(wrapped(T), col(C, CS))
```

The queried table is `raw(T)`. Since `wrapped(T)` and `raw(T)` are distinct constructors, the table equality side condition is false. With an explicit name, there is no generated `IndexName` part to compensate, so the whole statement returns false. This matches the public issue and is rejected by the intent spec.

## Machine-check commands to run later

These commands are intentionally recorded, not executed:

```sh
cd fvk
kompile mini-ddl-references.k --backend haskell
kast --backend haskell schema-unique-spec.k
kprove schema-unique-spec.k
```

Expected result after a successful machine check:

```text
#Top
```

## Test recommendation

No tests were modified. No hidden tests were inspected. Because this proof is constructed but not machine-checked, no test should be removed on its basis.

Useful tests to keep or add outside this task:

- An explicit-name `UniqueConstraint` or unique SQL statement over a column that is later removed should be deleted from `deferred_sql`.
- A generated-name unique statement should still report the same column reference.
- A PostgreSQL opclass-backed unique index should still report the same column reference through `IndexColumns`.

## Residual risk

The K model is a small semantics fragment for the DDL-reference object graph, not a full Python or Django semantics. It is property-complete for the audited bug because it preserves the distinguishing axis: raw table name versus `Table` wrapper.

The result is partial correctness for statement construction and reference-query behavior. It does not prove SQL rendering, feature-gate behavior, query compiler behavior, or migration end-to-end execution.
