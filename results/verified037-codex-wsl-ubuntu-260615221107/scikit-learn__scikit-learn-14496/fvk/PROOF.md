# Constructed FVK Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`,
tests, Python, or project code were run.

## Claims

The formal core is in:

- `fvk/mini-optics-size.k`
- `fvk/optics-size-spec.k`

The primary claim says that the fractional-size branch rewrites to
`roundPy(maxF(two, scaled))`, an integer-valued count. This is the abstract K
form of the V2 source expression:

```python
int(round(max(2, size * n_samples)))
```

The secondary claim says absolute integer counts greater than 1 pass through
unchanged for this audit.

## Proof Sketch

1. Start with a state satisfying `_validate_size(size, n_samples, name)` and
   the branch guard `size <= 1`.
2. Symbolically evaluate `size * n_samples` to the scaled floating value.
3. Apply `max(2, scaled)` so the value to be rounded is at least 2.
4. Apply Python `round`, then `int`. The explicit outer `int(...)` is the
   proof-relevant step for the reported failure: regardless of whether the
   rounded value is represented by a Python integer or another numeric scalar,
   the value passed downstream is an integer count.
5. Therefore the normalized count is an integer and satisfies the documented
   lower bound. This discharges PO2.
6. In `compute_optics_graph`, the same local variable is passed to
   `NearestNeighbors(n_neighbors=min_samples)`, so the issue's float-type
   failure cannot occur on the fractional branch. This discharges PO3.
7. In `cluster_optics_xi`, both fractional `min_samples` and fractional
   `min_cluster_size` follow the same expression. If `min_cluster_size is
   None`, it is assigned after `min_samples` has been normalized, so it also
   receives the rounded integer value. This discharges PO4 and PO5.
8. The `compute_optics_graph` docstring now includes `float between 0 and 1`,
   discharging PO6.

## V1 Falsification

V1 used:

```python
max(2, int(size * n_samples))
```

For `size=0.26` and `n_samples=10`, V1 computes `2`, while the public issue's
rounding form computes `3`. That violates the "rounded" obligation from IE4
and IE8 and is recorded as F1. V2 replaces truncation with
`int(round(max(2, size * n_samples)))`.

## Residual Risk

This proof is partial and scoped. It verifies the normalization obligation that
caused the reported failure. It does not prove termination, performance,
nearest-neighbor correctness, OPTICS reachability ordering, or Xi label
correctness. Those are unchanged frame behavior for this source patch.

The mini-K model abstracts Python floating-point values and the exact
tie-breaking behavior of `round`. That proof capability gap is F4/PO7. The
runtime source now uses Python's built-in `round` and `int`, so the code-level
decision is aligned with the public issue even though the lightweight formal
model is not a full Python semantics.

## Test Recommendations

No tests were edited. If tests were allowed, add or keep tests that compare:

- `OPTICS(min_samples=fraction)` with `OPTICS(min_samples=rounded_count)` for
  fractions whose product is not already integral.
- `cluster_optics_xi(..., min_samples=fraction)` with the same rounded integer
  threshold.
- `OPTICS(min_cluster_size=fraction)` with the corresponding rounded integer
  threshold.

Do not remove any tests unless the K commands below are actually run and return
`#Top`, and even then keep integration, performance, and out-of-domain tests.

## Reproduce The Machine Check

These commands were not run in this benchmark environment:

```sh
kompile fvk/mini-optics-size.k --backend haskell
kast --backend haskell fvk/optics-size-spec.k
kprove fvk/optics-size-spec.k
```

Expected constructed outcome for the abstraction claims: `#Top`, subject to
the PO7 float-semantics boundary.
