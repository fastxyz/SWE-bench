# FVK Iteration Guidance

Status: constructed, not machine-checked.

## Verdict

V1 stands. No additional source edits are justified by the FVK findings.

## Decision Trace

Keep the V1 expression:

```python
coord_names = self._coord_names & variables.keys() | set(new_variables)
```

Reasons:

- F-001 shows the pre-fix bug and the exact stale-name transition.
- PO-1 through PO-5 prove the V1 expression removes the stale name in the MCVE
  and restores non-negative data-variable length.
- F-002 plus PO-6 through PO-8 prove V1 preserves surviving level coordinates
  and replacement index variables.
- F-003 rejects the narrower `DataVariables.__len__` alternative because it
  would leave the internal coordinate-name invariant broken.

## Recommended Next Development Step

If test edits become allowed later, add a regression test equivalent to:

```python
ds = xr.Dataset(coords={"a": ("x", [1, 2, 3]), "b": ("x", ["a", "b", "c"])})
actual = ds.set_index(z=["a", "b"]).reset_index("z", drop=True)
expected = xr.Dataset(coords={"a": ("z", [1, 2, 3]), "b": ("z", ["a", "b", "c"])})
assert_identical(actual, expected, check_default_indexes=False)
```

This session must not add that test.

## Machine-Check Step For Later

Do not treat tests as redundant unless the K artifacts are accepted and checked:

```sh
kompile fvk/mini-xarray-reset-index.k --backend haskell
kast --backend haskell fvk/reset-index-coord-names-spec.k
kprove fvk/reset-index-coord-names-spec.k
```

## Residual Risk

- The FVK model intentionally abstracts value-level pandas index behavior. It
  proves the name-set invariant that caused the reported failure.
- The proof is constructed, not machine-checked.
- No test execution was performed.
