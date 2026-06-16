# Baseline Notes

## Root cause

`ProjectState.__init__()` still treated `real_apps` as a defensive public input:
truthy values were accepted as any iterable and converted with `set(real_apps)`.
The issue states that all internal call sites now pass `real_apps` as a `set`
when it is provided, so the constructor should enforce that internal contract
instead of silently accepting and converting other iterable types.

## Changed files

`repo/django/db/migrations/state.py`

- Updated `ProjectState.__init__()` so `real_apps=None` still creates an empty
  set.
- For every non-`None` `real_apps` value, added an `assert isinstance(real_apps,
  set)` and assigned the provided set directly.

`reports/baseline_notes.md`

- Added this report to document the cause, source change, and reasoning.

## Assumptions

- `ProjectState` construction is an internal migrations API for this argument,
  matching the issue description.
- Existing source call sites that pass `real_apps` continue to pass either
  `None` or a `set`. In particular, `MigrationLoader.unmigrated_apps` is
  initialized as a set and `ProjectState.clone()` passes through the existing
  set.
- Empty sets should be treated as provided values. The new `None` check makes
  this explicit and asserts the type for empty and non-empty sets alike.

## Alternatives considered

- Keeping the previous `set(real_apps)` conversion was rejected because it is
  the behavior the issue asks to remove.
- Adding a `TypeError` or broader runtime validation was rejected because the
  requested behavior is specifically to assert the set contract when
  `real_apps` is non-`None`.
- Copying the provided set with `set(real_apps)` after asserting was rejected
  because it would preserve the conversion/copying behavior rather than simply
  accepting the already-normalized internal value.
