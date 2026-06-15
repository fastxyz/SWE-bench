# FVK Specification for django__django-11740

Status: constructed, not machine-checked. No tests, Python code, or K tooling
were run.

## Intent-Only Specification

The migration autodetector must preserve the existing `AlterField` detection
behavior while ensuring that an `AlterField` whose new field definition is
relational carries dependency metadata for the referenced model. In the reported
case, changing `testapp1.App1.another_app` from `UUIDField` to
`ForeignKey(testapp2.App2)` must generate a migration for `testapp1` that
depends on the latest applicable migration of `testapp2`.

The dependency must be expressed through the autodetector's existing
`_auto_deps` mechanism, because `_build_migration_list()` is responsible for
turning those abstract dependencies into dependencies on generated migrations,
graph leaves, or `__first__`.

## Public Evidence Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | "Change uuid field to FK does not create dependency" | A scalar-to-FK `AlterField` must create a target-app dependency. | Encoded by C1 and PO1. |
| E2 | `benchmark/PROBLEM.md` | "I think the correct solution will be create dependency for App2." | The generated migration must depend on `testapp2` when the altered FK points to `testapp2.App2`. | Encoded by C1, C3, PO1, PO3. |
| E3 | public hint | "AlterField should pick this up." | The `AlterField` path, not only `AddField`, is responsible for relation dependencies. | Encoded by C1 and PO1. |
| E4 | public hint | "dependencies can be retrieved by using self._get_dependencies_for_foreign_key(new_field)" | The fix should reuse the existing dependency helper instead of constructing custom dependency tuples. | Encoded by C2 and PO2. |
| E5 | public hint | "depend on the latest migration of the referenced app instead of the initial one though as the aforementioned method should handle" | The abstract dependency must be suitable for `_build_migration_list()` to resolve to the current graph leaf or generated migration. | Encoded by C3 and PO3. |
| E6 | source code | `_generate_added_field()` already uses `_get_dependencies_for_foreign_key()` for related fields. | Relation dependency behavior for altered fields should match the established add-field behavior. | Supporting evidence for C1/C2. |
| E7 | task instruction | "Do not modify any test files" and "do not attempt to run tests, Python, or K framework tooling" | Verification artifacts must be reasoned-only, and tests must remain untouched. | Reflected in PROOF and ITERATION_GUIDANCE. |

## Scope and Domain

The verified slice is the `generate_altered_fields()` branch where:

- `(app_label, model_name, field_name)` exists in both old and new field sets;
- `old_field_dec != new_field_dec`;
- the alteration is represented as `AlterField` rather than a remove/add pair
  (`both_m2m or neither_m2m`);
- the selected emitted field has `field.remote_field` and
  `field.remote_field.model`.

Frame conditions:

- Non-relational altered fields still receive no relation dependency metadata.
- The remove/add path for concrete-to-M2M and M2M-to-concrete changes remains
  unchanged.
- Existing default-preservation and one-off default prompting behavior remains
  unchanged.
- No public method signatures or operation shapes are changed.

## Formal Claims in English

C1. For every in-scope altered field whose emitted field is relational,
`generate_altered_fields()` appends an `operations.AlterField` to
`generated_operations[app_label]` with `_auto_deps` containing every dependency
returned by `_get_dependencies_for_foreign_key(field)`.

C2. `_get_dependencies_for_foreign_key(field)` is the only new dependency source
used by the altered-field path, preserving existing handling for swappable
targets and explicit through models.

C3. For every external auto-dependency `(target_app, target_model, None, True)`
on an `AlterField`, `_build_migration_list()` either waits for generated
operations in `target_app`, depends on the latest generated migration for
`target_app`, depends on the target app's graph leaf, or falls back to
`(target_app, "__first__")` when no graph leaf exists.

C4. For non-relational altered fields, the dependency list passed to
`add_operation()` remains empty, so unrelated scalar alterations keep their prior
dependency behavior.

C5. The change is public-API compatible: it adds data to the internal `_auto_deps`
field of generated operations but does not change method signatures, operation
constructor arguments, field deconstruction, or migration operation types.

## Embedded Formal Core

The abstract mini-K files `fvk/mini-autodetector.k` and
`fvk/autodetector-spec.k` model the property-carrying part of the algorithm:
whether the emitted altered field is relational and which dependency list is
attached to the generated operation. They intentionally abstract away Django
model rendering, questioner prompts, and graph data structures except where
those are part of the claimed dependency property.

The proof commands that would be run in an environment with K installed are:

```sh
kompile fvk/mini-autodetector.k --backend haskell
kast --backend haskell fvk/autodetector-spec.k
kprove fvk/autodetector-spec.k
```

Expected result if the abstract model and claims are accepted by K:
`#Top` for all claims.

## Adequacy Audit

| Claim | Public-intent match | Result |
| --- | --- | --- |
| C1 | Directly matches E1-E4: `AlterField` must pick up FK dependencies. | Pass |
| C2 | Directly matches E4 and local source evidence E6. | Pass |
| C3 | Directly matches E5 and the source behavior of `_build_migration_list()`. | Pass |
| C4 | Frame condition derived from the issue scope and no unrelated-refactor requirement. | Pass |
| C5 | Compatibility condition derived from the task's minimal-source-change requirement. | Pass |

No claim is derived solely from V1 behavior. The V1 code is treated as the
candidate implementation checked against C1-C5.

## Public Compatibility Audit

Changed symbol: `MigrationAutodetector.generate_altered_fields()`.

Compatibility result: pass. The function signature is unchanged, its callers are
unchanged, and it still emits the same operation type for the altered-field path.
The only changed observable is migration dependency calculation for relational
`AlterField` operations, which is the required public behavior.
