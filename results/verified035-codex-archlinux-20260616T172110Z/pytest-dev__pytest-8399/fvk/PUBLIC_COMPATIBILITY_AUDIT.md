# Public Compatibility Audit

Constructed, not machine-checked.

## Changed Public Symbols

None.

The V1 patch changes only explicit `name=` strings passed to
`pytest.fixture(...)` for generated internal autouse fixtures. It does not
change public function signatures, methods, classes, hook specifications,
virtual dispatch calls, return types, or storage formats.

## Generated Fixture Names

The changed names are fixture argnames visible through fixture introspection.
The issue itself identifies the non-underscore forms as the bug and states that
the expected behavior is an underscore-prefixed private name. These generated
names are not documented user fixture APIs; they are implementation-specific
names used to speed up lookup.

Potential compatibility concern: a user could have depended on requesting the
buggy generated fixture name directly. This is rejected as a public-compatibility
blocker because:

- the issue requires the names to be private;
- the fixtures are autouse generated implementation details;
- the old visible names had no docstrings and are reported as CI noise rather
  than supported APIs;
- no documented public symbol or signature changes.

Status: no source compatibility repair is required beyond V1.
