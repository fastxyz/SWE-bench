# Public Compatibility Audit

## Changed symbols

`repo/sphinx/cmd/quickstart.py`

- `ask_user(d: Dict) -> None`: signature unchanged. On successful non-conflict
  paths it continues to populate `d` and return `None`. On an existing-project
  path it now reaches the pre-existing `sys.exit(1)` intent immediately instead
  of prompting for a replacement path first.
- `main(argv: List[str]) -> int`: signature unchanged. It now converts the
  `SystemExit(1)` raised by the interactive existing-project branch into an
  integer return status, matching the rest of the command's return-code style.

## Callsite search

Public source callsites found in this workspace:

- `quickstart.py`: `main()` calls `ask_user(d)` in the interactive branch.
- `tests/test_quickstart.py`: direct `ask_user(d)` calls exercise successful
  non-conflict paths; those paths are unchanged by the guard.
- `sphinx.ext.apidoc`: imports `EXTENSIONS` and calls `qs.generate(...)`; it
  does not call `ask_user()` or `quickstart.main()`.

## Compatibility verdict

No public signature, return shape on successful paths, virtual dispatch, or
producer/consumer data shape changed. The behavior change is intentionally
limited to the existing-project conflict branch described in the issue.
