# FVK Spec

Constructed, not machine-checked.

## Target Observable

The observable under audit is fixture-listing visibility for generated
unittest/xunit autouse fixtures in `pytest --fixtures`.

The listing path in `repo/src/_pytest/python.py::_showfixtures_main` filters by
`fixturedef.argname`; for non-verbose output it skips any fixture whose argname
starts with `_`. The generated setup/teardown fixtures under audit all pass an
explicit `name=` to `@pytest.fixture`, so the relevant observable is that
registered fixture name.

## Intended Contract

For every generated fixture in the xunit/unittest setup family:

1. If a generated fixture is registered, its fixture argname starts with `_`.
2. With `verbose <= 0`, `pytest --fixtures` does not print that generated
   fixture.
3. With `verbose > 0`, the generated fixture remains available to the fixture
   manager and may be printed.
4. The generated fixture's scope, autouse status, implementation body, cleanup
   behavior, and attachment point are unchanged by the privacy fix.

## Name Templates

The specified generated fixture names are:

- `_unittest_{setup_name}_fixture_{obj.__qualname__}` for unittest
  `setUpClass` and unittest `setup_method` injection through
  `_make_xunit_fixture`.
- `_xunit_setup_module_fixture_{self.obj.__name__}`.
- `_xunit_setup_function_fixture_{self.obj.__name__}`.
- `_xunit_setup_class_fixture_{self.obj.__qualname__}`.
- `_xunit_setup_method_fixture_{self.obj.__qualname__}`.

## Frame Conditions

These properties must be preserved:

- `scope=` values are unchanged.
- `autouse=True` is unchanged.
- The nested fixture functions and their setup/teardown call paths are
  unchanged.
- The private attributes used to attach generated fixtures to modules/classes
  are unchanged.
- Public function signatures and dispatch shapes are unchanged.

## Public Intent Ledger Summary

See `fvk/PUBLIC_EVIDENCE_LEDGER.md` for the full ledger. Critical entries:

- E2 establishes underscore-prefix naming as the privacy mechanism.
- E3 establishes the non-verbose/verbose fixture-listing distinction.
- E5 establishes that the full generated fixture family must be covered.
- E6 connects the source-level `name=` edit to the fixture listing observable.

## Formal Artifacts

- `fvk/mini-fixture-names.k` models only generated fixture-name rendering and
  fixture listing visibility.
- `fvk/generated-fixture-privacy-spec.k` states claims C1-C8 for private
  generated names, hiding in non-verbose listing, and verbose availability.

The formal model is intentionally abstract: it verifies the name-generation and
listing-filter property, not full Python execution or pytest collection.
