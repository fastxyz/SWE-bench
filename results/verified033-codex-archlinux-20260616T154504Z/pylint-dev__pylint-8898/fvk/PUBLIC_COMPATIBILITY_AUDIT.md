# Public Compatibility Audit

Status: constructed, not machine-checked.

Changed symbols:

- Added private helper `pylint.config.argument._split_regex_csv`.
- Changed private transformer body `pylint.config.argument._regexp_csv_transfomer`.

Compatibility checks:

- Public option key `"regexp_csv"` is unchanged.
- Function signature of `_regexp_csv_transfomer(value: str) -> Sequence[Pattern[str]]` is unchanged.
- Return shape remains an ordered sequence of compiled `Pattern[str]` objects.
- Generic CSV parsing and non-regex CSV option behavior are unchanged.
- Path-specific regex CSV parsing (`regexp_paths_csv`) is unchanged because the issue and option under audit are `regexp_csv` name-regex options.

Result:

- No public API or virtual-dispatch compatibility issue found.
- Existing public test `test_csv_regex_error` conflicts with issue intent and is classified as SUSPECT in `fvk/FINDINGS.md`, not as a compatibility blocker.
