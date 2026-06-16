# SPEC

Status: constructed, not machine-checked.

## Scope

This FVK pass audits the migration-optimizer behavior named by the public issue:

`CreateModel(name=N, fields=F, options=O, bases=B, managers=M0)` followed by
`AlterModelManagers(name=N, managers=M1)` should optimize to a single
`CreateModel(name=N, fields=F, options=O, bases=B, managers=M1)`.

The audited source unit is `CreateModel.reduce()` in
`repo/django/db/migrations/operations/models.py`. Supporting state semantics are
read from `CreateModel.state_forwards()`, `AlterModelManagers.state_forwards()`,
and `ProjectState.alter_model_managers()`.

## Intent Spec

I1. Same-model `CreateModel + AlterModelManagers` is reducible to a single
`CreateModel`.

I2. The replacement `CreateModel` must carry the final manager list from
`AlterModelManagers`.

I3. The replacement must preserve the original `CreateModel` name, fields,
options, and bases.

I4. Manager semantics are replacement semantics, not merge semantics.

I5. The optimization must be guarded by the same normalized model name. An
`AlterModelManagers` for another model must not be absorbed into this
`CreateModel`.

I6. Empty manager lists are in-domain. If `AlterModelManagers(..., managers=[])`
is applied, the optimized `CreateModel` must represent final managers `[]`.

## Public Evidence Ledger

E1. Source: `benchmark/PROBLEM.md`

Quoted evidence: "During migration optimization, CreateModel + AlterModelOptions
is reduced to just CreateModel, with the model options. Similarly, CreateModel +
AlterModelManagers can become just CreateModel."

Semantic obligation: encode a reducer postcondition for same-model
`CreateModel + AlterModelManagers` that returns one `CreateModel`.

Status: encoded by PO1 and K claim `CREATE-ALTER-MANAGERS-REDUCES`.

E2. Source: existing code pattern in `CreateModel.reduce()`

Quoted evidence: the `AlterModelOptions` branch returns `CreateModel(self.name,
fields=self.fields, options=options, bases=self.bases, managers=self.managers)`.

Semantic obligation: same operation-family reduction should preserve untouched
constructor arguments.

Status: encoded by PO2. Used only as implementation pattern evidence, not as the
primary intent.

E3. Source: `AlterModelManagers.state_forwards()`

Quoted evidence: it calls `state.alter_model_managers(app_label,
self.name_lower, self.managers)`.

Semantic obligation: the operation's own managers are the final manager value.

Status: encoded by PO3.

E4. Source: `ProjectState.alter_model_managers()`

Quoted evidence: `model_state.managers = list(managers)`.

Semantic obligation: managers are replaced by the alter operation's list; they
are not appended to or merged with existing managers.

Status: encoded by PO3 and PO7.

E5. Source: `ModelOperation.references_model()` and existing same-model guards
in `CreateModel.reduce()`.

Quoted evidence: operations compare lowercase model names before applying
same-model reductions.

Semantic obligation: the new reduction only fires for equal normalized model
names.

Status: encoded by PO4.

E6. Source: `CreateModel.__init__()`

Quoted evidence: `self.managers = managers or []`.

Semantic obligation: `managers=[]` remains a valid final manager state and
should not preserve an older nonempty manager list.

Status: encoded by PO7.

## Formal Domain

Let:

- `N` be a normalized model name.
- `F` be an arbitrary field list accepted by `CreateModel`.
- `O` be an arbitrary options mapping accepted by `CreateModel`.
- `B` be an arbitrary bases tuple accepted by `CreateModel`.
- `M0` be the original manager list on the `CreateModel`.
- `M1` be the manager list on `AlterModelManagers`, including the empty list.

The primary in-domain operation pair is:

`C = CreateModel(N, F, O, B, M0)`

`A = AlterModelManagers(N, M1)`

## Required Postconditions

P1. `C.reduce(A, app_label)` returns a one-element list.

P2. The only element is `CreateModel(N, F, O, B, M1)`.

P3. Applying `[C, A]` to a project state produces a model state whose
`fields/options/bases/managers` tuple is `(F, O, B, list(M1))`.

P4. Applying the optimized one-operation list to the same starting state
produces the same tuple `(F, O, B, list(M1))`.

P5. For `AlterModelManagers(N2, M1)` where `N2 != N`, this specific reduction
does not construct `CreateModel(N, F, O, B, M1)`.

## Adequacy Audit

The formal claim says exactly the issue's intended behavior: same-model
`CreateModel + AlterModelManagers` reduces to one `CreateModel` with final
managers. It is not stronger on ordering than the public issue because manager
list order is part of the operation payload and is preserved verbatim from
`AlterModelManagers`. It is not weaker because it covers arbitrary manager
lists, including empty lists.

The spec does not claim full correctness of every `CreateModel.reduce()` branch.
It frames all untouched branches as residual existing behavior and proves the
newly required manager reduction against the state-equivalence obligation.

## K Artifacts

The constructed K core is in:

- `fvk/mini-migration-optimizer.k`
- `fvk/create-model-reduce-spec.k`

Exact commands to machine-check later, not executed in this environment:

```sh
kompile fvk/mini-migration-optimizer.k --backend haskell
kast --backend haskell fvk/create-model-reduce-spec.k
kprove fvk/create-model-reduce-spec.k
```
