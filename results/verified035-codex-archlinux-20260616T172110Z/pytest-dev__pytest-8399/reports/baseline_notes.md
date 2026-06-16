# Baseline Notes

## Root cause

Pytest injects generated autouse fixtures to run unittest-style and xunit-style
setup/teardown hooks. These fixtures are intentionally internal, but their
registered fixture names no longer started with an underscore. Because
`pytest --fixtures` hides underscore-prefixed fixtures unless verbose output is
requested, the generated fixtures became visible in normal fixture listings and
appeared as undocumented public fixtures.

## Changed files

`repo/src/_pytest/unittest.py`

- Updated the generated unittest setup/teardown fixture name from
  `unittest_...` to `_unittest_...`.
- This covers generated fixtures for `setUpClass`/`tearDownClass` and unittest
  `setup_method`/`teardown_method` handling while preserving the same scope,
  autouse behavior, and uniqueness suffix.

`repo/src/_pytest/python.py`

- Updated generated xunit setup/teardown fixture names from `xunit_...` to
  `_xunit_...`.
- This covers module, function, class, and method xunit setup/teardown fixtures.
  Only the public-facing fixture registration name changed; the injected helper
  function names and private attributes used to attach them to modules/classes
  were left unchanged.

## Assumptions and alternatives considered

- I assumed the intended privacy signal is the fixture registration name passed
  via `name=...`, because that is what fixture listing uses and what the issue
  examples display.
- I considered renaming the Python helper functions themselves, but rejected it
  because those names are not the fixture names shown by `pytest --fixtures`
  when an explicit `name=` is provided.
- I considered adding filters to fixture listing output, but rejected that as a
  broader behavior change. Restoring the underscore prefix on generated internal
  fixtures matches the previous behavior described in the issue and keeps the
  fix local to fixture injection.
- I did not modify tests because the benchmark instructions require leaving the
  test suite fixed and hidden.
