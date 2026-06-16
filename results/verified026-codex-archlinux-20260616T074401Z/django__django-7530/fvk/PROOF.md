# FVK Proof

Status: constructed, not machine-checked. No tests, Python, `kompile`, `kast`,
or `kprove` were run.

## Claims Proved in the Constructed Model

C1. `newPairs(Apps)` emits only valid app-local pairs.

C2. `newPairs(Apps)` contains every app-local pair before runtime
short-circuiting.

C3. For each selected non-dummy database alias, the consistency-history check is
called exactly when some valid pair is allowed by the router.

C4. The V1 patch preserves alias selection, dummy-engine skipping, and router
call shape.

Formal artifacts:

- `fvk/mini-python-router.k`
- `fvk/makemigrations-router-spec.k`

## Constructed Proof Sketch

### C1: No Invalid Pair

V1 binds `app_config` first, then binds `model` from
`app_config.get_models()`. The router call uses the same `app_config` binding
for the app label and the nested `model` binding for the model name:

```python
router.allow_migrate(
    connection.alias,
    app_config.label,
    model_name=model._meta.object_name,
)
```

By the semantics of `AppConfig.get_models()`, each yielded model belongs to that
app config. Therefore each emitted pair satisfies `ValidPair(Apps, pair)`.

### C2: Valid-Pair Completeness

Ignoring `any()` short-circuiting, the nested generator has the form:

```python
for app_config in app_configs
for model in app_config.get_models()
```

Structural induction on the finite app-config list:

- Base: empty app list emits no pairs, which is complete for the empty valid
  pair set.
- Step: for head app `A`, the inner generator emits exactly
  `(A.label, object_name(M))` for each `M` in `models(A)`. By induction, the
  tail emits all valid pairs for the remaining apps. Concatenation emits all
  valid pairs for the whole list.

Runtime `any()` may stop after the first allowed pair. That is compatible with
the existential gate because later calls are unnecessary once the database is
known to require a consistency check.

### C3: History-Check Gate

The condition is:

```python
connection.settings_dict['ENGINE'] != 'django.db.backends.dummy' and any(...)
```

For a dummy engine, the left conjunct is false, so
`loader.check_consistent_history(connection)` is not reached.

For a non-dummy engine, Python `any()` over the V1 pair stream returns true iff
some router call over that stream returns true. By C1 and C2, the stream is
exactly the valid app-local pair stream up to short-circuiting. Therefore the
loader check is reached iff some valid app/model pair is allowed to migrate on
that alias.

### C4: Frame Conditions

V1 does not edit:

- the assignment to `aliases_to_check`;
- the `sorted(aliases_to_check)` loop;
- the dummy-engine guard;
- the call to `loader.check_consistent_history(connection)`;
- the `router.allow_migrate()` method name or keyword set.

Therefore those behaviors are preserved.

## Bug Localization

The pre-fix code computed:

```python
for app_label in consistency_check_labels
for model in apps.get_models(app_label)
```

`Apps.get_models()` doesn't accept an app label in this source version. Passing
`app_label` as a positional argument set `include_auto_created` instead and
returned project-wide models. This created the cross-product reported in the
issue.

V1 removes that mechanism by pairing `app_config.label` only with models from
`app_config.get_models()`.

## Machine-Check Commands

These commands are recorded for a future environment. They were not run here.

```sh
kompile fvk/mini-python-router.k --backend haskell
kast --backend haskell fvk/makemigrations-router-spec.k
kprove fvk/makemigrations-router-spec.k
```

Expected outcome if the abstract mini-semantics is accepted by K:

`kprove` discharges the claims to `#Top`.

## Residual Risk

The proof is partial correctness only. It doesn't prove command termination,
performance, real Python semantics, or the correctness of K itself.

The mini-K model abstracts Django objects to app labels, model names, finite
model lists, connection aliases, and router truth values. That abstraction is
adequate for this issue because the reported observable is exactly the
`(app_label, model_name)` pairs passed to routers.

No tests are recommended for deletion. Test removal would require a real
machine-checked proof plus a separate mapping from tests to the checked claims.
