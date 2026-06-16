# FVK ITERATION GUIDANCE for pytest-dev__pytest-6197

Status: V1 stands unchanged.

## Decision

Do not revise production code in the FVK phase. The audit found that V1 already
matches the public-intent boundary:

- package discovery may still create `Package` collectors;
- package discovery no longer imports `__init__.py`;
- package parents still mount before child module items are created;
- configured `__init__.py` test collection through `python_files` remains intact.

## If Another Iteration Were Requested

Recommended focused tests, without editing the fixed test suite here:

1. Directory traversal with `foobar/__init__.py` raising and no files under
   `foobar` that match `python_files` should not import `foobar`.
2. Directory traversal with `foobar/__init__.py` raising and only non-test
   modules under `foobar` should not import `foobar`.
3. Directory traversal with nested packages that contain no collected modules
   should not import any nested package initializer.
4. A package-level `pytestmark = pytest.mark.skip` should still apply to tests in
   sibling `test_*.py` modules.
5. With `python_files = *.py`, tests defined in `__init__.py` should still be
   collected.

## Open Questions

No user clarification is required for the reported issue. The remaining risks
are outside this fix's public intent: arbitrary third-party collection hooks can
execute arbitrary code, and this abstract proof was not machine-checked.

## Next Pass Guidance

If a later audit finds an import path not modeled here, localize it by event:
identify the first operation that emits `Import(P)` before any `Module.collect()`
for a descendant module. A valid repair should remove or defer that operation
without changing hook signatures or disabling configured initializer tests.
