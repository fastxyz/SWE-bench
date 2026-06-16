# PROOF

Status: constructed, not machine-checked.

## Claim

For any valid `CreateModel(N, F, O, B, M0)` and same-model
`AlterModelManagers(N, M1)`, `CreateModel.reduce()` returns a one-element list
containing `CreateModel(N, F, O, B, M1)`. Applying that one-operation list has
the same final model-state managers as applying the original two operations.

## K Core

The mini semantics and claims are:

- `fvk/mini-migration-optimizer.k`
- `fvk/create-model-reduce-spec.k`

Commands to run later, not executed here:

```sh
kompile fvk/mini-migration-optimizer.k --backend haskell
kast --backend haskell fvk/create-model-reduce-spec.k
kprove fvk/create-model-reduce-spec.k
```

Expected machine-check outcome after a valid K environment is available:
`kprove` discharges the claims to `#Top`.

## Proof Sketch

1. The public issue imposes the postcondition that same-model
   `CreateModel + AlterModelManagers` can become a single `CreateModel`.
   This is PO1.

2. In V1, the new branch is reached only when the right operation is an
   `AlterModelManagers` and the normalized model names are equal. This discharges
   PO4.

3. The branch constructs `CreateModel(self.name, fields=self.fields,
   options=self.options, bases=self.bases, managers=operation.managers)`.
   The first four constructor arguments are framed from the original
   `CreateModel`, discharging PO2.

4. `AlterModelManagers.state_forwards()` calls
   `state.alter_model_managers(..., self.managers)`, and
   `ProjectState.alter_model_managers()` assigns
   `model_state.managers = list(managers)`. Therefore the final manager list of
   the original two-operation sequence is `list(M1)`, not a merge with `M0`.
   The V1 branch uses `operation.managers`, discharging PO3.

5. State equivalence follows by symbolic composition:

   Original sequence:

   - `CreateModel(N, F, O, B, M0)` creates model state
     `(fields=F, options=O, bases=B, managers=list(M0))`.
   - `AlterModelManagers(N, M1)` replaces managers with `list(M1)`.
   - Final state tuple is `(F, O, B, list(M1))`.

   Optimized sequence:

   - `CreateModel(N, F, O, B, M1)` creates model state
     `(fields=F, options=O, bases=B, managers=list(M1))`.
   - Final state tuple is `(F, O, B, list(M1))`.

   Both paths end in the same model-state tuple, discharging PO5.

6. For `M1 = []`, both paths end with `managers=[]`, because
   `alter_model_managers()` replaces with `list([])` and the optimized
   `CreateModel` receives `managers=[]`. This discharges PO7.

7. `AlterModelManagers.database_forwards()` and `database_backwards()` are no-op
   methods, so deleting the separate alter operation does not remove schema
   work. The surviving `CreateModel` database behavior is unchanged. This
   discharges PO6.

## Residual Risk

This proof is partial and constructed only. It does not prove termination of the
whole migration optimizer loop, and it does not machine-check the K claims. The
trusted base is the adequacy of the mini semantics for operation values and
manager replacement, plus the future K toolchain run.

## Test Guidance

No tests were run or edited. After machine-checking, a narrow unit test asserting
that `CreateModel + AlterModelManagers` optimizes to one `CreateModel` with
`operation.managers` would be subsumed by PO1 through PO5. Existing integration,
serialization, and optimizer-loop tests should be kept because this constructed
proof covers only the local reduction contract.
