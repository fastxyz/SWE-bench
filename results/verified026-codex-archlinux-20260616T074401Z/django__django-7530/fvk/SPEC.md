# FVK Spec: makemigrations router consistency checks

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Target

Source under audit:

`repo/django/core/management/commands/makemigrations.py`

Audited block: the migration-history consistency gate in
`Command.handle()`, before conflict detection.

## Intent-Only Specification

I1. Source: `benchmark/PROBLEM.md`

Evidence: "`makemigrations` incorrectly calls `allow_migrate()` for each app
with all the models in the project rather than for each app with the app's
models."

Obligation: every router call made by this consistency check must pair an app
label with a model from that same app.

I2. Source: `benchmark/PROBLEM.md`

Evidence: "It broke the router I use because it was passing invalid
combinations for shards since not all shards have the same models."

Obligation: invalid `(app_label, model_name)` combinations must not be
observable by routers, including routers that reject or fail on nonexistent
app/model combinations.

I3. Source: implementation comment in `makemigrations.py`

Evidence: "At least one model must be migrated to the database."

Obligation: a non-dummy database is checked for consistent migration history
iff at least one valid app/model pair is allowed to migrate there. The existing
short-circuit behavior of `any()` is allowed: it may stop after the first
allowed valid pair, but it must not call routers with invalid pairs before that
point.

I4. Source: implementation of `Apps.get_models()` and `AppConfig.get_models()`

Evidence: `Apps.get_models()` takes `include_auto_created` and
`include_swapped`; `AppConfig.get_models()` iterates only that app config's
model mapping.

Obligation: app-local iteration must use `AppConfig.get_models()` or an
equivalent source of models already known to belong to the chosen app label.

I5. Source: existing call shape in `makemigrations.py`

Evidence: the preexisting call used
`router.allow_migrate(connection.alias, app_label,
model_name=model._meta.object_name)`.

Obligation: this issue does not require changing the public router call shape,
`model_name` casing, or hints. Those are frame conditions for this repair.

## Formal Domain

The proof domain is the consistency-history gate after the app registry and
database connection handler are initialized:

- `Apps` is a finite ordered list of app configs.
- Each app config has a label `label(A)` and a finite model list
  `models(A)`.
- Each model `M` in `models(A)` has `object_name(M)`.
- `allow(alias, label, model_name)` is the observable router predicate for the
  call shape used by this command.
- The app registry is stable for the duration of the command.
- The proof is partial correctness only; termination of Django management
  command execution is not proved.

## Definitions

Valid pair:

`ValidPair(Apps, (L, MN))` holds iff there exists an app config `A` in `Apps`
and a model `M` in `models(A)` such that `L = label(A)` and
`MN = object_name(M)`.

Candidate V1 pair stream:

`PairsV1(Apps) = concat([ (label(A), object_name(M)) for M in models(A) ] for
A in Apps)`

Buggy pre-fix pair stream:

`PairsOld(Apps) = concat([ (label(A), object_name(M)) for M in all_models(Apps)
] for A in Apps)`

The issue is exactly that `PairsOld` contains invalid pairs whenever at least
two apps don't have identical model sets.

## Required Postconditions

S1. No invalid router call:

Every pair emitted by `PairsV1(Apps)` satisfies `ValidPair(Apps, pair)`.

S2. Completeness up to short-circuiting:

For every valid pair `(label(A), object_name(M))`, that pair appears in
`PairsV1(Apps)`. During command execution, `any()` may stop before reaching
later valid pairs if an earlier valid pair is allowed.

S3. Correct history-check gate:

For a non-dummy connection alias, `loader.check_consistent_history(connection)`
is reached iff there exists a valid pair `P` in `PairsV1(Apps)` such that
`allow(alias, P.label, P.model_name)` returns true.

S4. Database-selection frame:

The repair preserves the existing database selection rule:

- if `settings.DATABASE_ROUTERS` is set, check all aliases in `connections`;
- otherwise, check only `DEFAULT_DB_ALIAS`;
- skip dummy database engines.

S5. Router-call-shape frame:

The repair preserves the existing call shape:

`router.allow_migrate(connection.alias, app_config.label,
model_name=model._meta.object_name)`

No `model` hint or `model_name` casing change is required by this issue.

## Adequacy Gate

The formal claims in `fvk/makemigrations-router-spec.k` paraphrase to S1-S4.
Those claims are adequate for I1-I4 because they express exactly the observable
bug: invalid app/model combinations sent to routers during the consistency
check. S5 is a frame condition, not a proof that the existing call-shape
convention is globally ideal.

The audit found no public-intent obligation requiring a broader router API
change. Therefore V1 may stand unchanged.
