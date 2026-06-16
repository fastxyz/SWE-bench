# Iteration Guidance

Status: V1 stands unchanged.

## Decision

Keep the V1 code change:

```python
fixture_dirs = [os.fspath(fixture_dir) for fixture_dir in settings.FIXTURE_DIRS]
```

This line discharges PO-001 through PO-004 without changing public APIs,
exception messages, or test files.

## Why no V2 source edit was made

FVK found one resolved code bug, F-001, and one broader ambiguous question,
F-002. F-002 concerns canonical path aliases whose `os.fspath()` strings differ
but whose later `os.path.realpath()` values may match. The public issue is
specifically about `Path` instances bypassing duplicate detection; the evidence
does not clearly require broadening this patch to all canonical aliases.

## Suggested future work

If maintainers want duplicate detection to use the same canonical paths as the
eventual fixture search list, a future patch should explicitly specify and test
that policy. The likely shape would be to compare `os.path.realpath()` values
for both configured fixture directories and app default fixture directories
before validation. That should be treated as a separate behavior change because
it may reject configurations that were not rejected by the historical exact
string comparison.

## Suggested tests for a normal development environment

No tests were added or run in this task. In a normal environment, useful public
tests would be:

- `FIXTURE_DIRS=[Path(path), path]` raises the duplicate error.
- `FIXTURE_DIRS=[path, Path(path)]` raises the duplicate error.
- `FIXTURE_DIRS=[Path(app_default_fixture_dir)]` raises the default-directory
  error.
- `FIXTURE_DIRS=[Path(nonduplicate_fixture_dir)]` still loads fixtures.
