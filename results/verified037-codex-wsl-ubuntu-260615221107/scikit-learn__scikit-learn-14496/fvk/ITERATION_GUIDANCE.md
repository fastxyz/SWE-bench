# FVK Iteration Guidance

Status: constructed, not machine-checked.

## Code Decision

V1 should not stand unchanged. Finding F1 showed that V1 truncated fractional
sample counts, while the public issue and existing docstrings specify rounded
counts. V2 changes only the three fractional conversions in
`repo/sklearn/cluster/optics_.py` to:

```python
int(round(max(2, size * n_samples)))
```

No broader OPTICS refactor is justified by the proof obligations.

## Next Tests To Add If Constraints Allow

- A `compute_optics_graph` or `OPTICS.fit` coverage case where
  `min_samples * n_samples` is non-integral and rounds differently from
  truncation.
- A `cluster_optics_xi` coverage case for fractional `min_samples`.
- A `cluster_optics_xi` or `OPTICS(..., min_cluster_size=...)` coverage case
  for fractional `min_cluster_size`.
- Boundary cases where the scaled value is below 2, exactly 2, and above 2.

## Tests To Keep

Keep existing OPTICS integration tests, clustering-label tests, warning tests,
and invalid-input tests. The constructed proof only covers the local
normalization obligation and is not a substitute for algorithmic or integration
coverage.

## Future Formal Work

- Replace the abstract `roundPy`/`FVal` model with a real Python numeric
  semantics if exact float tie behavior becomes part of the required contract.
- Extend formalization to `_validate_size` error behavior if public intent
  later requires integer-valued floats above 1 to be accepted or rejected in a
  specific way.
- Run the emitted K commands in an environment with K before treating any test
  as proof-redundant.
