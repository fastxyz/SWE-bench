# FVK Proof Obligations

Status: constructed, not machine-checked.

## PO1 - AlterField dependency attachment

Statement: In the in-scope `generate_altered_fields()` branch, if the emitted
field has `remote_field.model`, the operation passed to `add_operation()` must
receive a dependency list containing `_get_dependencies_for_foreign_key(field)`.

Evidence: SPEC E1-E4.

Discharge argument: V1 initializes `dependencies = []`, extends it with
`self._get_dependencies_for_foreign_key(field)` when `field.remote_field` and
`field.remote_field.model` are truthy, then passes `dependencies=dependencies`
to `self.add_operation()` for `operations.AlterField(...)`.

Findings traced: F1, F2.

Status: discharged by source inspection and abstract proof claim
`ALTER-REL-DEPS`.

## PO2 - Reuse existing dependency helper

Statement: The altered-field path must use the same helper as existing related
field creation paths, preserving swappable-target and explicit-through-model
dependency behavior.

Evidence: SPEC E4, E6.

Discharge argument: V1 calls `_get_dependencies_for_foreign_key(field)` directly.
That helper emits a `("__setting__", setting_name, None, True)` dependency for
swappable targets, otherwise emits the target model dependency, and appends the
explicit through-model dependency when present.

Findings traced: F1, F2.

Status: discharged by source inspection.

## PO3 - Migration-list dependency resolution

Statement: An external auto-dependency on a referenced app/model must be
converted by `_build_migration_list()` into an actual migration dependency on a
generated migration, a graph leaf, or `__first__`.

Evidence: SPEC E2, E5.

Discharge argument: `_build_migration_list()` iterates `operation._auto_deps`.
When the dependency app differs from the operation app, it first waits for
matching generated operations in that app. Once satisfied, it records a
dependency on the latest generated migration for that app, or, in chop mode,
uses `graph.leaf_nodes(dep[0])[0]` when available and `(dep[0], "__first__")`
otherwise. Therefore the dependency attached in PO1 reaches the final migration
dependency list.

Findings traced: F1.

Status: discharged by source inspection and proof sketch.

## PO4 - Frame non-relation behavior

Statement: Scalar altered fields without a relational target must keep prior
dependency behavior.

Evidence: SPEC C4 and no-unrelated-refactor task constraint.

Discharge argument: V1 adds dependencies only under
`if field.remote_field and field.remote_field.model:`. For scalar fields the list
remains empty and `add_operation()` receives an empty list, equivalent to the
previous `_auto_deps = []` behavior.

Findings traced: F2.

Status: discharged by source inspection and abstract proof claim
`ALTER-NONREL-FRAME`.

## PO5 - Frame remove/add path

Statement: Alterations between M2M and concrete fields must continue using the
existing remove/add generation path.

Evidence: SPEC scope and frame conditions.

Discharge argument: V1 changes only the `both_m2m or neither_m2m` branch before
the `AlterField` operation is added. The `else` branch still calls
`_generate_removed_field()` and `_generate_added_field()` unchanged.

Findings traced: none.

Status: discharged by source inspection.

## PO6 - Public compatibility

Statement: The fix must not change public signatures, operation constructor
shapes, or migration operation types.

Evidence: SPEC C5.

Discharge argument: V1 changes only the internal dependency argument passed to
`add_operation()`. `generate_altered_fields()` keeps the same signature and still
constructs `operations.AlterField(model_name=..., name=..., field=...,
preserve_default=...)`.

Findings traced: F2.

Status: discharged by source inspection.

## PO7 - Verification and test constraints

Statement: This pass must not run tests/tooling and must not edit tests.

Evidence: SPEC E7.

Discharge argument: The proof is marked constructed, not machine-checked, and no
test files were modified. Commands are recorded in PROOF.md for later use.

Findings traced: F3, F4.

Status: discharged by process compliance.
