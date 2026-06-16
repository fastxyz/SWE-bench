# FVK Spec

Status: constructed, not machine-checked.

## Scope

The target is `src/_pytest/skipping.py::pytest_runtest_makereport` as patched
in V1. The verified observable is the final `TestReport` state relevant to the
issue: `outcome`, `longrepr`, and `wasxfail`.

The proof abstracts the Python hook into a deterministic mini state machine in
`fvk/mini-pytest-report.k`. The abstraction keeps the property under audit:
whether a skipped report with an internal skip location is rewritten to the item
location. It intentionally does not model unrelated report fields.

## Public Intent Ledger

| ID | Source | Evidence | Obligation |
| --- | --- | --- | --- |
| E1 | Prompt | `@pytest.mark.skip` / `skipif` marks skip a test | Marked skips are in scope. |
| E2 | Prompt | Expected `test_it.py:3: unconditional skip` | Marked skip location points to the item definition. |
| E3 | Prompt | Buggy `src/_pytest/skipping.py:238` output | Internal skip raise site is not intended behavior. |
| E4 | Prompt | "`--runxfail` is only about xfail" | `runxfail` must not affect marker-skip location reporting. |
| E5 | Code | `skipped_by_mark_key` records marker skips | The rewrite is gated to marker-driven skips. |
| E6 | Code | `reports.py` initializes skip `longrepr` from exception crash site | The makereport hook is the correct layer to rewrite the location. |
| E7 | Code | xfail branches set `wasxfail` and outcomes | Non-runxfail xfail behavior is a frame condition. |

## Contract

1. If `runxfail` is true and a skipped setup report was caused by a skip or
   skipif mark, the hook rewrites `longrepr` from the internal skip raise site
   to the item definition location, preserving the skip reason.

2. If `runxfail` is true and the skipped report was not caused by a skip or
   skipif mark, the hook does not apply the marker-skip item-location rewrite.

3. If `runxfail` is true, xfail-specific report rewrites remain disabled.

4. If `runxfail` is false, the existing xfail-specific report rewrites remain
   reachable and semantically unchanged.

## Formal Core

Formal semantics: `fvk/mini-pytest-report.k`

Formal claims: `fvk/pytest-skipping-spec.k`

Claims:

| Claim | Obligation |
| --- | --- |
| C1 | Marked skip plus `runxfail=True` rewrites `internalSkip(R)` to `itemSkip(R)`. |
| C2 | Unmarked skip plus `runxfail=True` leaves `internalSkip(R)` unchanged. |
| C3 | `xfailExc` plus `runxfail=True` does not set `wasxfail`. |
| C4 | `xfailExc` plus `runxfail=False` still sets `wasxfail` and skipped outcome. |

Machine-check commands, not executed in this environment:

```sh
kompile fvk/mini-pytest-report.k --backend haskell
kast --backend haskell fvk/pytest-skipping-spec.k
kprove fvk/pytest-skipping-spec.k
```

Expected machine-check result after installing/running K: `#Top`.
