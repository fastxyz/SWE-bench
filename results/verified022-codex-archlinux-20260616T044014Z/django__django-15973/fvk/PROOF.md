# FVK Proof

Status: constructed, not machine-checked. No tests, Python, `kompile`, `kast`, or `kprove` were run.

## Claim Summary

The production fix is correct if these claims hold:

1. The helper keeps returning the dependency for the relation target or swappable target.
2. The helper returns an additional dependency for the explicit through model by resolving `field.remote_field.through`.
3. The returned dependency list is consumed by migration graph construction before operation optimization.
4. No public API, tuple shape, or no-through behavior changes.

These are PO-1 through PO-5 in `fvk/PROOF_OBLIGATIONS.md`.

## Symbolic Proof Sketch

Let `target = remote_field_model`, `through = field.remote_field.through`, and `ctx = (app_label, model_name)`.

Case 1: `field.swappable_setting is None`.

The helper executes the non-swappable branch and computes:

```text
dep_target = resolve_relation(target, *ctx) + (None, True)
dependencies = [dep_target]
```

This discharges PO-1.

Subcase 1a: `through` is falsy.

The guard `if getattr(field.remote_field, "through", None)` is false, so the helper returns `[dep_target]`. This discharges PO-4.

Subcase 1b: `through` is truthy.

V1 computes:

```text
dep_through = resolve_relation(through, *ctx) + (None, True)
dependencies.append(dep_through)
```

For the reported field, `target = "variavel.VariavelModel"` and `through = "fonte_variavel.FonteVariavelModel"`, so the resulting app labels are `variavel` and `fonte_variavel`. This discharges PO-2 and closes finding F1.

Case 2: `field.swappable_setting is not None`.

The helper computes the target dependency as `("__setting__", setting_name, None, True)`. The through branch is independent of that target branch and still computes `resolve_relation(through, *ctx) + (None, True)`. This discharges PO-5.

Graph-ordering composition:

Related fields generated during model creation call the helper and attach `dependencies=list(set(dependencies))` to the `AddField` operation. `_build_migration_list()` checks external app dependencies before a migration is created. `_optimize_migrations()` runs only after the migration list exists. Therefore a corrected through dependency reaches graph splitting before optimization can fold operations. This discharges PO-3 and closes finding F2.

Compatibility composition:

The changed expression is inside an existing branch and preserves function arguments, return type, tuple shape, and all callers. This discharges PO-5 and closes finding F3.

## Machine-check Commands

Do not run these in this benchmark session. They are provided for reproducibility only.

```sh
kompile fvk/mini-migration-deps.k --backend haskell
kast --backend haskell fvk/migration-autodetector-spec.k
kprove fvk/migration-autodetector-spec.k
```

Expected result after a future machine check: `#Top` for all reduced claims.

## Test Guidance

No tests were modified or run.

Potential public tests to add outside this task:

- Autodetector test where a new model has `ManyToManyField("variavel.VariavelModel", through="fonte_variavel.FonteVariavelModel")` and the generated `fonte` migration depends on `fonte_variavel`.
- Regression test where a swappable target plus explicit concrete through preserves the setting dependency and includes the through dependency.
- Frame test where a normal many-to-many field without explicit through does not gain an unrelated dependency.

No test should be removed based on this constructed proof until the K claims and normal Django test suite have been run in an environment where execution is allowed.

## Residual Risk

This proof is a focused partial-correctness argument over dependency calculation and its static graph-ordering consumers. It does not machine-check full Django behavior, database schema editing, or migration execution. The public issue only requires correcting the missing explicit-through dependency, and no additional production-code change is justified by the FVK findings.
