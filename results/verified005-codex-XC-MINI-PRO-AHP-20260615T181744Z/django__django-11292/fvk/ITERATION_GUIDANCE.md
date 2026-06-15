# Iteration Guidance

Status: V2 repair applied.

## Required Code Change Applied

Finding F1 required a V2 code edit. `testserver` now exposes `--skip-checks` and
passes the caller's skip decision to the delegated `runserver` call. This closes
PO4 while preserving PO5.

## V1 Decisions Kept

- Keep the `BaseCommand` parser addition conditional on
  `requires_system_checks`. Finding F3 explains why no-op exposure on commands
  with no system-check path is not required by public intent.
- Keep the `runserver` explicit-check handling. Finding F2 and PO3 show that the
  automatic base hook cannot cover `runserver`.
- Keep migration-check behavior unchanged. Finding F4 and PO7 show the issue is
  about system checks, not migration warnings.
- Keep `call_command()` unchanged. PO5 preserves the existing programmatic
  default and avoids changing a separate public API contract.

## Future Machine-Check Step

In an environment with K installed, run:

```sh
cd fvk
kompile mini-django-management.k --backend haskell
kast --backend haskell management-skip-checks-spec.k
kprove management-skip-checks-spec.k
```

Expected result: `#Top`.

## Future Test Step

When an execution environment exists, add or run tests that distinguish the V1
bug from V2:

- command-line `testserver` without `--skip-checks` should pass
  `skip_checks=False` to `runserver`;
- command-line `testserver --skip-checks` should pass `skip_checks=True`;
- programmatic `call_command('testserver')` should continue passing
  `skip_checks=True`.

Do not remove existing tests based only on these constructed artifacts.
