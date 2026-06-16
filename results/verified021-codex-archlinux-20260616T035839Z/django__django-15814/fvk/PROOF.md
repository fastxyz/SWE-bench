# Constructed Proof

Status: constructed, not machine-checked.

## Artifacts

- Semantics fragment: `fvk/mini-python.k`
- Claims: `fvk/django-deferred-spec.k`
- Human-readable spec: `fvk/SPEC.md`
- Findings: `fvk/FINDINGS.md`
- Proof obligations: `fvk/PROOF_OBLIGATIONS.md`

## Commands to Machine-Check Later

These commands are recorded for a real K environment. They were not executed in
this workspace.

```sh
cd fvk
kompile mini-python.k --backend haskell
kast --backend haskell django-deferred-spec.k
kprove django-deferred-spec.k
```

Expected machine-check result after the commands are run in a suitable
environment: `kprove` returns `#Top` for the stated claims.

## Proof Sketch

### PROXY-ONLY-PK

Start with:

```text
buildOnlyMask(anotherModel, proxyCustomModel, customFk, nameField)
~> defaultColumns(customModel)
```

The semantics gives `concrete(proxyCustomModel) = customModel`. The fixed
`buildOnlyMask` rule therefore writes:

```text
key(customModel, idField)
key(customModel, nameField)
```

into the load mask. The subsequent `defaultColumns(customModel)` rule selects a
field exactly when `hasKeyField(loadMask, customModel, field)` is true. Both
`idField` and `nameField` are therefore selected. This discharges `PO2`, `PO3`,
and `PO4`.

### CONCRETE-TARGET-FRAME

Start with:

```text
buildOnlyMask(anotherModel, customModel, customFk, nameField)
~> defaultColumns(customModel)
```

For a concrete target, `concrete(customModel) = customModel`. The same rule
therefore writes the same concrete key it would have used before normalization.
Default-column selection includes both `idField` and `nameField`. This
discharges `PO5`.

### LEGACY-PROXY-COUNTEREXAMPLE

The legacy rule records:

```text
key(proxyCustomModel, idField)
key(customModel, nameField)
```

When `defaultColumns(customModel)` checks concrete-model membership, it finds
`nameField` but not `idField`. This derives the reported mechanism:
`RelatedPopulator` receives an init list without the primary key attname and can
raise `ValueError: 'id' is not in list`. This discharges `PO6` by localizing the
bug and showing V1 removes it.

## Residual Risk

This proof is partial correctness for the mask-construction and column-selection
slice. It does not prove SQL execution, database backend behavior, query result
ordering, performance, or termination. It is also constructed, not
machine-checked, because this workspace forbids running K tooling.

## Test Recommendation

No tests are redundant unless the K claims are machine-checked and mapped to
specific public tests. A regression test for
`select_related("assignee").only("assignee__status")` through a proxy foreign
key should be added when test edits are allowed. No test files were changed in
this task.

