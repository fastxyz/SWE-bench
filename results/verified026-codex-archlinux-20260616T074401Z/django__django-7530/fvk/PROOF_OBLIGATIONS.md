# FVK Proof Obligations

Status: constructed, not machine-checked.

## PO1: Valid app-local pair generation

Claim:

For every app config `A` in `apps.get_app_configs()` and every model `M` yielded
by `A.get_models()`, the pair passed to the router is
`(A.label, M._meta.object_name)`.

Why it matters:

This is the positive form of the public issue's requirement: pair each app with
the app's own models.

Discharge:

V1 uses:

```python
for app_config in app_configs
for model in app_config.get_models()
```

and passes `app_config.label` with `model._meta.object_name`.

Finding trace: F1.

## PO2: No invalid router calls

Claim:

Every pair passed to `router.allow_migrate()` by this consistency check is a
valid pair from PO1. There is no reachable call where an app label from one app
is paired with a model yielded only by a different app config.

Why it matters:

Routers for sharded deployments may reject nonexistent app/model combinations.

Discharge:

`AppConfig.get_models()` iterates only the models registered for that app
config. Since the label and model are drawn from the same `app_config` binding,
the pair is app-local by construction.

Finding trace: F1.

## PO3: Completeness of valid pairs before short-circuit

Claim:

The generated pair stream contains every valid pair
`(A.label, M._meta.object_name)` for every app config `A` and model `M` yielded
by `A.get_models()`. Runtime may observe only a prefix because Python `any()`
short-circuits after the first truthy router result.

Why it matters:

The fix must not skip a whole app's models when deciding whether any model may
migrate to a database.

Discharge:

The nested generator enumerates all app configs and all models of each app
config in the absence of short-circuiting. `any()` short-circuiting existed
before V1 and is consistent with the gate's existential meaning.

Finding trace: F1, F2.

## PO4: Correct history-check condition

Claim:

For each non-dummy connection alias selected for consideration,
`loader.check_consistent_history(connection)` is called iff at least one valid
app/model pair is allowed by `router.allow_migrate()` for that alias.

Why it matters:

The consistency check should run only on databases where migrations are relevant
to at least one model, while avoiding invalid router probes.

Discharge:

The condition remains:

```python
connection.settings_dict['ENGINE'] != 'django.db.backends.dummy' and any(...)
```

V1 changes only the generator feeding `any(...)`. By PO1-PO3, that generator is
exactly the valid app/model pair stream.

Finding trace: F2.

## PO5: Database-selection frame

Claim:

V1 preserves the alias set:

- routers configured: `connections`;
- no routers configured: `[DEFAULT_DB_ALIAS]`;
- dummy engines skipped.

Why it matters:

The issue concerns pair construction, not which databases are considered.

Discharge:

V1 did not edit the alias-selection or dummy-engine code.

Finding trace: F2.

## PO6: Router call-shape compatibility frame

Claim:

V1 preserves the existing `allow_migrate()` call signature and keyword payload:

```python
router.allow_migrate(
    connection.alias,
    app_config.label,
    model_name=model._meta.object_name,
)
```

Why it matters:

The public issue evidence requires valid pairings. It doesn't require changing
`model_name` casing, adding hints, or routing through `allow_migrate_model()`.

Discharge:

The source diff changes `app_label` and model iteration provenance only. It
does not change the router method, positional arguments, or keyword set.

Finding trace: F3.

## PO7: Verification honesty

Claim:

All proof results must be labeled constructed, not machine-checked, and no test
removal is justified in this environment.

Why it matters:

The task forbids running tests, Python, and K tooling.

Discharge:

The artifacts include the K commands that would be run later but do not report
their execution.

Finding trace: F4.
