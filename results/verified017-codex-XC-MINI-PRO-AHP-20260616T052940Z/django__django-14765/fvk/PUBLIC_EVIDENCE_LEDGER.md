# PUBLIC EVIDENCE LEDGER

Status: constructed from allowed public inputs only.

## E1

- Source: `benchmark/PROBLEM.md`.
- Evidence: "ProjectState.__init__() can assume its real_apps argument is a
  set".
- Obligation: non-`None` `real_apps` values are expected to already have type
  `set`.

## E2

- Source: `benchmark/PROBLEM.md`.
- Evidence: "instead of checking that real_apps is a set and converting it to a
  set if not, it can just assert that it's a set when non-None."
- Obligation: replace defensive conversion with an assertion for every
  non-`None` value.

## E3

- Source: `benchmark/PROBLEM.md`.
- Evidence: "Presumably the construction of new ProjectState objects is part
  of Django's internal API."
- Obligation: source callsite compatibility is required; accepting arbitrary
  external iterables is not an obligation for this fix.

## E4

- Source: `repo/django/db/migrations/loader.py`.
- Evidence: `self.unmigrated_apps = set()` and later calls forwarding that
  value.
- Obligation: known producer for `real_apps` is set-valued.

## E5

- Source: `repo/django/db/migrations/state.py`.
- Evidence: `ProjectState.clone()` passes `real_apps=self.real_apps`.
- Obligation: once a state is constructed under the contract, clone preserves
  the set-valued contract.

