# Baseline Notes

## Root cause

`verify_needs_extensions()` compared the configured minimum version and the
loaded extension version as raw strings:

```python
reqversion > extension.version
```

That makes version segments compare lexicographically instead of numerically.
For example, a loaded version such as `0.10.0` can compare as older than a
required version such as `0.6.0`, even though it is newer by normal version
ordering.

## Files changed

`repo/sphinx/extension.py`

- Imported `InvalidVersion` and `Version` from `packaging.version`. `packaging`
  is already an install requirement and is already used elsewhere in Sphinx.
- Added `_is_version_requirement_satisfied()` to compare valid version strings
  using PEP 440 version ordering.
- Updated `verify_needs_extensions()` to use that helper instead of the raw
  string comparison while preserving the existing error path for extensions
  that do not report a version.

## Assumptions and alternatives considered

- I assumed `needs_extensions` values and extension metadata versions are meant
  to be ordinary version strings, consistent with the configuration
  documentation and the reported `0.6.0` versus `0.10.0` failure.
- I kept a fallback to the previous string comparison when either side is not a
  valid PEP 440 version. This avoids turning existing sentinel/custom values
  such as Sphinx's `builtin` metadata into new `InvalidVersion` failures.
- I considered changing the separate `needs_sphinx` and `require_sphinx`
  comparisons as well, since they also use string ordering in nearby code, but
  rejected that as outside the issue scope. The reported failure is specifically
  in `needs_extensions`.
- I did not modify tests because the benchmark instructions prohibit changing
  test files, and I did not run tests or execute code because this session has
  no execution environment.
