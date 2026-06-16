# Iteration Guidance

Status: constructed, not machine-checked.

## Code decision

V1 stands unchanged. The audit found the original defect F1 and confirmed that
V1 discharges the relevant obligations:

- PO2: marker-skip location rewrite is reachable under `runxfail`.
- PO3: xfail-specific rewrites remain disabled under `runxfail`.
- PO4: normal non-runxfail xfail behavior is preserved.
- PO5: runtime skips are not broadened into marker skips.

No additional source edit is justified by the FVK findings.

## Commands to run later

Do not run these in the current task environment. In a K-enabled environment,
use:

```sh
kompile fvk/mini-pytest-report.k --backend haskell
kast --backend haskell fvk/pytest-skipping-spec.k
kprove fvk/pytest-skipping-spec.k
```

Then run the pytest regression suite normally. Test deletion remains
recommendation-only and conditioned on machine-checking.

## Suggested regression coverage

When test editing is allowed, add or keep coverage for:

- `@pytest.mark.skip` with `pytest -rs --runxfail` reports the test item line.
- `@pytest.mark.skipif(True, reason=...)` with `pytest -rs --runxfail` reports
  the test item line and reason.
- An imperative runtime skip remains governed by existing runtime-skip
  reporting rather than the marker-skip rewrite.
- Normal xfail behavior without `--runxfail` still reports xfail/xpass as
  before.
