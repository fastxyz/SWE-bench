# PROOF OBLIGATIONS

Status: constructed, not machine-checked.

## PO1: Same-model reduction returns one operation

For all in-domain `N, F, O, B, M0, M1`:

`reduce(CreateModel(N, F, O, B, M0), AlterModelManagers(N, M1))`

must return:

`[CreateModel(N, F, O, B, M1)]`

Evidence: E1.

Finding coverage: FVK-F1.

Status: discharged by the V1 branch in `CreateModel.reduce()`.

## PO2: Non-manager fields are framed

The reduced `CreateModel` must preserve:

- `name = self.name`
- `fields = self.fields`
- `options = self.options`
- `bases = self.bases`

Evidence: E1 and E2.

Finding coverage: FVK-F1.

Status: discharged by the V1 constructor call.

## PO3: Managers are replaced by `operation.managers`

The reduced `CreateModel` must use `M1`, the manager list carried by
`AlterModelManagers`, not `M0` and not `M0 + M1`.

Evidence: E3 and E4.

Finding coverage: FVK-F2.

Status: discharged by `managers=operation.managers`.

## PO4: Same-model guard prevents cross-model absorption

The new reduction branch must require `self.name_lower == operation.name_lower`.

Evidence: E5.

Finding coverage: FVK-F4.

Status: discharged by the V1 branch guard.

## PO5: State equivalence of original and optimized operation lists

Applying `[CreateModel(N, F, O, B, M0), AlterModelManagers(N, M1)]` to a project
state must produce the same model-state tuple as applying
`[CreateModel(N, F, O, B, M1)]`.

Expected final tuple:

`(fields=F, options=O, bases=B, managers=list(M1))`

Evidence: E3 and E4.

Finding coverage: FVK-F1 and FVK-F2.

Status: discharged by composing `CreateModel.state_forwards()` with
`AlterModelManagers.state_forwards()`.

## PO6: Database behavior is preserved

`AlterModelManagers.database_forwards()` and `.database_backwards()` are no-ops,
so removing the separate alter operation must not remove database schema work.
The remaining `CreateModel` database behavior is unchanged.

Evidence: source code in `AlterModelManagers`.

Finding coverage: FVK-F1.

Status: discharged by inspection.

## PO7: Empty manager list remains final

For `M1 = []`, the reduced operation must produce a `CreateModel` whose final
state managers are `[]`.

Evidence: E4 and E6.

Finding coverage: FVK-F3.

Status: discharged by `managers=operation.managers` and `CreateModel.__init__()`
normalization.

## PO8: Honesty gate

The proof must be labeled constructed, not machine-checked, and no tests,
Python, or K commands may be run.

Evidence: user benchmark instructions and FVK honesty gate.

Finding coverage: FVK-F5.

Status: discharged by artifact labeling and by not executing the emitted
commands.
