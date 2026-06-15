# FVK Proof

Status: constructed, not machine-checked. The commands below were not run.

## Target Contract

For every altered field in the scoped `generate_altered_fields()` branch, if the
emitted new field is relational, the generated `AlterField` operation has
`_auto_deps` containing `_get_dependencies_for_foreign_key(field)`. The migration
builder then converts those abstract dependencies into concrete migration
dependencies using its existing dependency-resolution algorithm.

## Abstract K Model

The files `fvk/mini-autodetector.k` and `fvk/autodetector-spec.k` model the
dependency-carrying part of the code:

- `field(true, DEPS)` represents an emitted altered field with
  `remote_field.model`.
- `field(false, DEPS)` represents a non-relational emitted altered field.
- `genAlterField(FIELD)` represents the relevant `generate_altered_fields()`
  action.
- `alterField(FIELD, DEPS)` represents the operation stored through
  `add_operation()`.

The model abstracts Django object identity, field deconstruction, questioner
prompts, and app registry details because those do not affect whether the
dependency list is attached to the operation.

## Constructed Proof

PO1 / `ALTER-REL-DEPS`:

1. Start from a symbolic relational emitted field `field(true, DEPS)`.
2. The V1 source branch initializes `dependencies` to `[]`.
3. The condition `field.remote_field and field.remote_field.model` is true by
   the precondition.
4. The branch extends `dependencies` by `_get_dependencies_for_foreign_key(field)`.
   In the abstract model this is represented by `DEPS`.
5. `add_operation(..., dependencies=dependencies)` stores the generated
   `AlterField` with `_auto_deps = DEPS`.
6. Therefore every generated relational `AlterField` in the scoped branch carries
   the target dependency list.

PO2:

1. The only new dependency source is `_get_dependencies_for_foreign_key(field)`.
2. The helper is unchanged and already covers the target model, swappable
   settings, and explicit through models.
3. Therefore the altered-field path inherits the established dependency tuple
   semantics rather than creating a divergent tuple format.

PO3:

1. `_build_migration_list()` reads each operation's `_auto_deps`.
2. For external dependencies it waits until generated target-app operations are
   satisfied, or records a dependency on the latest generated target-app
   migration.
3. If the target app has no generated migration in this autodetection run, chop
   mode records the graph leaf when present, or `__first__` otherwise.
4. Therefore the dependency from PO1 reaches the final migration dependency list,
   including the reported case where `testapp1` must depend on `testapp2`.

PO4 / `ALTER-NONREL-FRAME`:

1. Start from a symbolic non-relational emitted field `field(false, DEPS)`.
2. The V1 relation guard is false.
3. `dependencies` remains empty.
4. `add_operation()` stores the generated operation with no relation dependency,
   preserving prior scalar alteration behavior.

PO5 and PO6 are frame obligations: V1 does not change the remove/add path,
function signatures, or `AlterField` constructor arguments.

## Reproduction of Machine Check

These commands are recorded for a future environment with K installed:

```sh
kompile fvk/mini-autodetector.k --backend haskell
kast --backend haskell fvk/autodetector-spec.k
kprove fvk/autodetector-spec.k
```

Expected result: `#Top` for the abstract claims. This pass did not run the
commands, so the result remains constructed, not machine-checked.

## Test Guidance

No tests were run and no test files were modified. A future test, if permitted,
should construct an old state with a scalar field and a new state with a
`ForeignKey` to another app, then assert that the generated migration for the
altering app depends on the referenced app's latest migration.

No test should be removed based on this constructed proof until the K artifacts
and the Django test suite have been run in an appropriate environment.

## Residual Risk

- The K model is an abstraction of the dependency-carrying algorithm, not a full
  Python or Django semantics.
- Partial correctness only: the proof establishes the dependency property when
  the scoped branch is reached.
- The result is not machine-checked in this environment.
