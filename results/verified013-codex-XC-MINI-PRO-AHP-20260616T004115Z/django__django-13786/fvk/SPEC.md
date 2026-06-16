# FVK Specification: django__django-13786

Status: constructed, not machine-checked.

## Scope

The audited unit is the `CreateModel.reduce()` branch for a following
`AlterModelOptions` operation on the same model in
`repo/django/db/migrations/operations/models.py`.

The observable behavior is the replacement operation list returned to
`MigrationOptimizer`: a singleton list containing a new `CreateModel` whose model
state is equivalent to applying the original `CreateModel` and
`AlterModelOptions` operations in sequence.

Branches for `DeleteModel`, `RenameModel`, field operations, together options,
and order-with-respect-to are outside the public issue's changed behavior. The
V1 fix does not alter those branches.

## Intent Spec

I-001. Squashing `CreateModel` with the corresponding `AlterModelOptions` must
preserve migration state semantics.

I-002. `AlterModelOptions(options={})` must clear model options governed by
`AlterModelOptions.ALTER_OPTION_KEYS` from the resulting squashed `CreateModel`.

I-003. An `AlterModelOptions` operation can set or override any option key it
contains.

I-004. Existing options that are not governed by `ALTER_OPTION_KEYS` and are not
overridden by the operation must remain on the squashed `CreateModel`.

I-005. The reduction must preserve the original `CreateModel` name, fields,
bases, and managers.

I-006. The public API shape must not change: `CreateModel.reduce(operation,
app_label)` still returns Django's normal `Operation.reduce()` result shape.

## Public Evidence Ledger

E-001. Source: `benchmark/PROBLEM.md`.
Quoted evidence: "squashmigrations does not unset model options when optimizing
CreateModel and AlterModelOptions".
Obligation: the optimized `CreateModel` must unset options when the following
`AlterModelOptions` omits them.
Status: encoded by PO-002 and PO-003.

E-002. Source: `benchmark/PROBLEM.md`.
Quoted evidence: "`AlterModelOptions(name=\"test_model\", options={})` is
squashed into the corresponding `CreateModel` operation, model options are not
cleared".
Obligation: the empty-options boundary case must remove all alterable option
keys from the squashed `CreateModel`.
Status: encoded by PO-003.

E-003. Source: `benchmark/PROBLEM.md`.
Quoted evidence: "`CreateModel.reduce()` sets the new options as
`options={**self.options, **operation.options}` ... with no logic to remove
options not found in `operation.options`".
Obligation: a plain merge is insufficient; omission from `operation.options`
has semantic force for alterable keys.
Status: encoded by PO-002.

E-004. Source: `benchmark/PROBLEM.md` public hint.
Quoted evidence: "take `AlterModelOptions.ALTER_OPTION_KEYS` in consideration
here like `AlterModelOptions.state_forwards` does".
Obligation: the reducer should use the same alterable-key removal boundary as
`AlterModelOptions.state_forwards()`.
Status: encoded by PO-002 through PO-005.

E-005. Source: implementation comment in
`repo/django/db/migrations/operations/models.py`.
Quoted evidence: "Model options we want to compare and preserve in an
AlterModelOptions op".
Obligation: `ALTER_OPTION_KEYS` is the exact set of keys whose absence from the
operation should clear prior values.
Status: encoded by PO-002 and PO-004.

E-006. Source: `MigrationOptimizer` docstring in
`repo/django/db/migrations/optimizer.py`.
Quoted evidence: "operations are merged into one if possible".
Obligation: replacement operations must be state-equivalent to the original
sequence, not merely syntactically shorter.
Status: encoded by PO-001 and PO-002.

## Formal Definitions

Let:

`M` be the original `CreateModel.options` map.

`A` be the following `AlterModelOptions.options` map.

`K` be the finite ordered list `AlterModelOptions.ALTER_OPTION_KEYS`.

`merge(M, A)` be Python dictionary merge `{**M, **A}`, where values from `A`
override values from `M`.

`dom(X)` be the key set of map `X`.

`R = reduce_options(M, A, K)` is defined pointwise for every key `x`:

1. If `x in dom(A)`, then `R[x] = A[x]`.
2. Else if `x in K`, then `x not in dom(R)`.
3. Else if `x in dom(M)`, then `R[x] = M[x]`.
4. Else `x not in dom(R)`.

This definition is independent of option values, including falsey values.
Presence in `A`, not truthiness of `A[x]`, controls whether an alterable key is
kept.

## Function Contract

Precondition:

`operation` is an `AlterModelOptions` instance, and
`self.name_lower == operation.name_lower`.

Postcondition:

`CreateModel.reduce(self, operation, app_label)` returns:

```text
[
    CreateModel(
        self.name,
        fields=self.fields,
        options=reduce_options(self.options, operation.options, operation.ALTER_OPTION_KEYS),
        bases=self.bases,
        managers=self.managers,
    )
]
```

Frame condition:

The reduction does not mutate `self.options`, `operation.options`,
`self.fields`, `self.bases`, or `self.managers`. It constructs a new options map
and a new `CreateModel`.

Compatibility condition:

The method signature and return shape remain unchanged. Nonmatching operations
continue through the existing branches or `super().reduce()`.

## Formal Core

The FVK run is constructed over a small map/list fragment rather than full
Python execution. The intended K claim, written here as the formal core to be
machine-checked in a fuller environment, is:

```k
// SPEC-PROVENANCE:
// - E-001/E-002: omitted AlterModelOptions keys must be cleared.
// - E-004/E-005: ALTER_OPTION_KEYS is the removal boundary.
// - E-006: optimized operation must be state-equivalent to original sequence.
claim
  <k> reduceAlterModelOptions(M:Map, A:Map, K:KeyList)
      => singletonCreateModelWithOptions(reduceOptions(M, A, K)) ... </k>
  requires sameModel ==Bool true
  ensures pointwiseOptionsEqual(
      resultOptions,
      stateForwardsOptions(M, A, K)
  ) ==Bool true
  [all-path]

// Loop/circularity over the finite key list K:
// processed keys already satisfy the three-way postcondition
//   present in A -> A value
//   absent from A and in processed K -> absent
//   not in K -> merge(M, A) value
// unprocessed keys still equal merge(M, A).
claim
  <k> removeMissingAlterKeys(K:KeyList, A:Map, O:Map)
      => expectedAfterRemoving(K, A, O) ... </k>
  requires finiteKeyList(K) ==Bool true
  [all-path]
```

Expected machine-check commands, not executed in this environment:

```sh
kompile fvk/mini-migration-options.k --backend haskell
kast --backend haskell fvk/create-model-reduce-spec.k
kprove fvk/create-model-reduce-spec.k
```

Expected outcome if the mini semantics matches the definitions above:
`kprove` discharges the claims to `#Top`.

## Adequacy Audit

A-001. The formal postcondition explicitly clears omitted alterable keys, so it
matches I-002 and does not preserve the reported legacy bug.

A-002. The formal postcondition preserves keys outside `ALTER_OPTION_KEYS` unless
overridden, so it matches I-004 and does not over-delete schema-related options.

A-003. The formal postcondition uses all keys present in `operation.options`, so
it matches `AlterModelOptions.state_forwards()` rather than a narrower
implementation-derived filter.

A-004. The frame condition covers name, fields, bases, and managers, matching
the public optimizer expectation that only the reducible option state changes.

A-005. No public signature or dispatch shape changes were made; compatibility is
unchanged.
