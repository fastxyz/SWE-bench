# ITERATION_GUIDANCE.md

Status: constructed, not machine-checked.

## Verdict

V1 stands unchanged. The FVK audit found the original bug as F1 and mapped it to
PO-1. V1 discharges PO-1 without breaking PO-2 through PO-7.

## Code Guidance

- Keep the conditional first-entry removal.
- Keep the `_remove_sys_path_entry` guard for `PYTHONPATH` cleanup targets.
- Keep the shifted indices for implicit leading and trailing `PYTHONPATH`
  cleanup when the first entry is preserved.
- Do not add path normalization unless public requirements are expanded beyond
  the exact `""`, `"."`, and `os.getcwd()` forms.
- Do not remove all later CWD-like entries globally.

## Test Guidance

Tests were not run or edited. Suggested public tests for maintainers:

- `sys.path = ["something", cwd, ...]`, no edge-colon `PYTHONPATH`:
  `"something"` is preserved.
- `sys.path = ["something", cwd, "/custom", ...]`,
  leading implicit-current-directory `PYTHONPATH`: `"something"` is preserved
  and the CWD-like implicit slot is removed.
- `sys.path = ["something", "/custom", cwd, ...]`,
  trailing implicit-current-directory `PYTHONPATH`: `"something"` is preserved
  and the trailing CWD-like implicit slot is removed.

## Verification Guidance

When a K environment is available, run:

```sh
cd fvk
kompile mini-python-syspath.k --backend haskell
kast --backend haskell modify-sys-path-spec.k
kprove modify-sys-path-spec.k
```

Until `kprove` returns `#Top`, treat proof-based test removal as only a
recommendation.
