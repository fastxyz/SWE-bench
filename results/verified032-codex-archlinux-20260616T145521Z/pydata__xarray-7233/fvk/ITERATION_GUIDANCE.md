# Iteration Guidance

Status: V1 confirmed; no additional source edit applied.

## Decision

Keep the V1 source change:

```python
should_be_coords = set(self.obj.coords)
```

The FVK audit found that this line is exactly the coordinate-preservation frame
condition required by the public issue.

## Trace to findings and obligations

- F1 identifies the pre-fix bug: intersecting coordinate names with
  `window_dim` drops non-dimension coordinates such as `day`.
- PO1 proves those original coordinate names are still present as variables in
  `reshaped`, so passing them to `set_coords` is valid.
- PO2 proves V1 preserves all original coordinate names in result coordinates.
- F2 records the confirmation that V1 satisfies the audited obligation.
- F3 explains why no further source edit is needed to force exact coordinate-set
  equality.
- F4 and PO3 confirm the shared DataArray path remains compatible.
- PO4 confirms no public API compatibility repair is needed.

## Next useful checks outside this constrained session

These are not to be run in this benchmark session, but are useful in a normal
development environment:

```sh
python -m pytest repo/xarray/tests/test_coarsen.py
kompile fvk/mini-xarray.k --backend haskell
kast --backend haskell fvk/coarsen-construct-spec.k
kprove fvk/coarsen-construct-spec.k
```

The expected behavioral test to add in a normal project would assert that a
non-dimension coordinate remains in `result.coords` after
`ds.coarsen(time=12).construct(time=("year", "month"))`.

