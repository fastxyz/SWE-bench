# PROOF

Status: constructed, not machine-checked.

## Theorem

For every app scanned by `MigrationLoader.load_disk()`, if its migrations module
imports successfully and exposes `__path__`, then the app is classified as
migrated and its migration names are discovered from `module.__path__`,
independent of whether `module.__file__` exists. Disabled migrations,
accepted missing modules, and imported non-package modules remain unmigrated.

## Proof sketch

1. Start from the successful-import branch of `load_disk()`.

2. V0 contained two guards before classification as migrated:
   `getattr(module, '__file__', None) is None` and
   `not hasattr(module, '__path__')`. The first guard captured namespace
   packages and sent them to `unmigrated_apps`.

3. V1 removes the `__file__` guard. The remaining successful-import
   classification branch is:

   - if `not hasattr(module, '__path__')`, add the app to `unmigrated_apps` and
     continue;
   - otherwise reload when needed, add the app to `migrated_apps`, and compute
     `migration_names` from `pkgutil.iter_modules(module.__path__)`.

4. Case analysis over import outcome:

   - `module_name is None`: unchanged disabled branch, unmigrated.
   - accepted missing module: unchanged `ImportError` branch, unmigrated.
   - other import error: unchanged propagation.
   - imported module without `__path__`: unchanged non-package branch,
     unmigrated.
   - imported module with `__path__` and truthy `__file__`: migrated, as before.
   - imported module with `__path__` and missing/`None` `__file__`: migrated,
     newly satisfying the namespace-package obligation.

5. The path-discovery postcondition follows by transitivity: after the
   successful package case reaches `self.migrated_apps.add(app_config.label)`,
   the next assignment computes `migration_names` from
   `pkgutil.iter_modules(module.__path__)`; the set comprehension preserves the
   existing filter on packages and `_`/`~` prefixes.

6. The downstream `migrate` observable follows from the frame condition that the
   public loader attributes keep their shape. `migrate` checks membership in
   `executor.loader.migrated_apps`; therefore moving namespace packages from
   `unmigrated_apps` to `migrated_apps` is exactly the public effect required by
   the issue.

## Formal core

The abstract K core is in:

- `fvk/mini-loader.k`
- `fvk/migration-loader-spec.k`

The central claim is:

```k
claim <k> classify(loaded(true, false, ENTRIES:List))
      => migrated(filterNames(ENTRIES)) </k>
  [all-path]
```

This claim is the formal paraphrase of "a namespace migrations package with
`__path__` and no `__file__` is migrated and discovered by path".

## Proof obligations discharged

- PO-NS-PACKAGE: discharged by absence of a `__file__` guard and presence of
  the `__path__` package guard.
- PO-PATH-DISCOVERY: discharged by the unchanged
  `pkgutil.iter_modules(module.__path__)` discovery.
- PO-FILTER: discharged by unchanged set comprehension filter.
- PO-NONPACKAGE: discharged by unchanged `not hasattr(module, '__path__')`
  branch.
- PO-DISABLED and PO-MISSING: discharged by unchanged branches before successful
  package classification.
- PO-COMPAT and PO-MIGRATE-CONSUMER: discharged by unchanged public loader API
  shape and downstream use of `migrated_apps`.

## Residual risk

This is a partial-correctness proof over a property-complete abstraction of the
loader branch. It does not prove Python import-system termination, third-party
import hook behavior, or actual K parser acceptance. Per task constraints, no
tests, Python, `kompile`, `kast`, or `kprove` commands were run.

## Commands to machine-check later

```sh
kompile fvk/mini-loader.k --backend haskell
kast --backend haskell fvk/migration-loader-spec.k
kprove fvk/migration-loader-spec.k
```

Expected result: `#Top` for all claims.

## Test guidance

Do not remove tests in this benchmark task. A future test suite should keep
integration coverage for `migrate`, import-error handling, and non-package
`migrations.py` behavior. A namespace migrations package test would be
subsumed by PO-NS-PACKAGE only after the K proof is actually machine-checked.
