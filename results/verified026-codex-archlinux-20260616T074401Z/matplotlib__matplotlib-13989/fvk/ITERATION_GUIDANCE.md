# Iteration Guidance

Status: constructed, not machine-checked.

## Code decision

V1 stands unchanged.

F-001 and PO-001 show that the original bug was caused by replacing
`hist_kwargs` when density was added. V1 changes that replacement into an
in-place addition, which is exactly the proof obligation.

F-002 and PO-003 show why the fix should remain guarded by `not stacked`.
Changing stacked density to pass `density=True` into `np.histogram` would
alter an existing manual-normalization path.

F-003 and PO-004 show why no additional range kwarg should be forced into the
multiple non-empty dataset path. That path already uses `bin_range` while
precomputing common bins.

## Recommended future tests

The fixed hidden/public test suite should include, if not already present, a
regression test equivalent to:

```python
_, bins, _ = plt.hist(np.random.rand(10), "auto", range=(0, 1), density=True)
assert bins[0] == 0
assert bins[-1] == 1
```

No test files are modified in this task.

## Open limits

The FVK proof does not replace integration tests for rendering, NumPy bin-edge
generation, unit conversion, cumulative histograms, log scaling, or autoscale
behavior. Keep those tests.
