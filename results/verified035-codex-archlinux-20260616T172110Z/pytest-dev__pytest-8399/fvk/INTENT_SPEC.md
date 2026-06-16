# Intent Spec

Constructed, not machine-checked.

## Public Intent Obligations

I1. Generated unittest setup/teardown fixtures are internal/private fixtures.

- Evidence: the issue says the expected previous behavior was that the generated
  fixture name "would start with an underscore" and would be printed only with
  the additional `-v` flag.
- Obligation: every generated unittest setup fixture name exposed to the fixture
  manager must begin with `_`.

I2. Generated xunit setup/teardown fixtures are the same family of internal
fixtures.

- Evidence: the issue hint says the problem "also seems to affect xunit style
  test-classes" and says "a similar change needs to be applied to the other
  generated fixtures."
- Obligation: every generated xunit setup fixture name exposed to the fixture
  manager must begin with `_`, not only the single class-level example.

I3. Normal `pytest --fixtures` output must hide these generated fixtures.

- Evidence: the issue explains that underscore-prefixed fixtures "only get
  printed if the additional `-v` flag was used."
- Obligation: for non-verbose fixture listing, a generated fixture whose name
  begins with `_` is not printed.

I4. Verbose fixture listing may still expose private fixtures.

- Evidence: the issue explicitly mentions the additional `-v` flag as the way
  to print underscore-prefixed fixtures.
- Obligation: the fix must not require removing the generated fixtures from the
  fixture manager; it only needs to restore private naming.

I5. Setup/teardown behavior is out of scope for change and must be preserved.

- Evidence: the reported breakage is fixture listing/no-docstring visibility,
  and the code comments describe these as hidden autouse fixtures that invoke
  existing setup/teardown hooks.
- Obligation: scope, autouse behavior, hook invocation, cleanup, and attachment
  of the generated fixtures must remain unchanged except for the registered
  fixture name.

## Domain

The domain is generated fixture registrations created by these source paths:

- `repo/src/_pytest/unittest.py::_make_xunit_fixture`
- `repo/src/_pytest/python.py::Module._inject_setup_module_fixture`
- `repo/src/_pytest/python.py::Module._inject_setup_function_fixture`
- `repo/src/_pytest/python.py::Class._inject_setup_class_fixture`
- `repo/src/_pytest/python.py::Class._inject_setup_method_fixture`

The audit does not specify user-authored fixtures, non-xunit fixtures, fixture
execution order, or hidden test behavior.
