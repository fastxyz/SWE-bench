# Iteration Guidance

Status: V1 stands. No source edit is recommended by this FVK pass.

## Decision

Keep the V1 implementation in `repo/src/_pytest/skipping.py` unchanged. Findings
FVK-F1 through FVK-F4 and obligations PO1 through PO8 justify the decision:

- the stale cache bug is localized to xfail marker evaluation freshness,
- V1 stores a marker-count freshness witness with the cached xfail value,
- V1 refreshes before call execution for setup-time dynamic markers,
- V1 refreshes before marker-based call-report handling for body-time dynamic
  markers,
- existing report precedence and xfail marker semantics are preserved,
- public APIs and hook signatures are unchanged.

## Future Validation Commands

These commands are provided for a future environment where execution is allowed.
They were not run here.

```sh
kompile fvk/mini-pytest-xfail.k --backend haskell
kast --backend haskell fvk/pytest-xfail-spec.k
kprove fvk/pytest-xfail-spec.k
```

Project test commands that would be useful later, also not run here:

```sh
python -m pytest testing/test_skipping.py
```

## Suggested Tests To Keep Or Add Later

Do not edit tests in this benchmark. In a normal project iteration, add or keep
coverage for:

- dynamic `request.node.add_marker(pytest.mark.xfail(reason="xfail"))` inside
  the test body followed by failure,
- the same path with a passing body to confirm XPASS behavior,
- `strict=True` on a dynamically added xfail marker,
- `raises=` match and mismatch on dynamically added xfail markers,
- `--runxfail` preserving normal pass/fail reporting,
- setup/fixture-time `run=False` dynamic xfail continuing to prevent call body
  execution.

## Residual Risks

The proof is constructed over a mini state-machine semantics, not the full pytest
runtime. It has not been machine-checked. Direct mutation of internal marker
lists that preserves xfail marker count is outside the public API and outside
this proof's domain.
