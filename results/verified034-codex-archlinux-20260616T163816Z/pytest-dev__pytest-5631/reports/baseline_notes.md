# Baseline Notes

## Root cause

`_pytest.compat.num_mock_patch_args` decides how many leading arguments were
created by `mock.patch` so `getfuncargnames` can avoid treating those generated
mocks as fixtures. When `mock` or `unittest.mock` is imported, the helper checked
whether a patching object used the default mock-creation sentinel with:

```python
p.new in sentinels
```

That membership test invokes equality. For explicit `new=` values that implement
vectorized or otherwise non-scalar equality, such as a NumPy array, comparing the
value to `mock.DEFAULT` can produce a non-boolean result. Python then attempts to
interpret that result as truthy during collection and raises `ValueError`.

## Changed files

`repo/src/_pytest/compat.py`

- Changed the sentinel check in `num_mock_patch_args` from equality-based
  membership to identity comparison against each known `DEFAULT` sentinel.
- This preserves the existing behavior for ordinary `@patch(...)` calls, where
  `p.new` is exactly the mock module's `DEFAULT` sentinel and therefore consumes
  a generated mock argument.
- Explicit `new=` values, including arrays and other objects with unusual
  equality semantics, are no longer compared with `==` and therefore do not
  fail during collection.

## Assumptions and alternatives considered

- I assumed that only the actual `mock.DEFAULT` or `unittest.mock.DEFAULT`
  sentinel object should count as a generated mock argument. This matches the
  purpose of the helper: explicit `new=` values do not add a positional mock
  argument to the decorated test function.
- I considered special-casing NumPy arrays or catching `ValueError`, but that
  would leave the same bug for other array-like or custom objects with
  non-boolean equality. Identity comparison is more direct because the code is
  looking for singleton sentinel objects.
- I kept the change localized to collection argument detection and did not
  modify tests, fixture discovery, or mock integration behavior elsewhere.
