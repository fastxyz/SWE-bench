# FVK Spec: OPTICS Fractional Size Normalization

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Scope

This FVK pass audits the V1 fix for the public issue
`scikit-learn__scikit-learn-14496`: fractional `min_samples` values in OPTICS
were scaled by `n_samples` but left as floats before count-sensitive use.

The formal core covers the changed normalization calculation:

```python
int(round(max(2, size * n_samples)))
```

for the `size <= 1` branch used by `compute_optics_graph` and
`cluster_optics_xi`. The full OPTICS graph construction, nearest-neighbor
search, reachability ordering loop, and Xi clustering algorithm are treated as
frame behavior for this issue. They are not claimed as formally verified here.

## Intent-Only Specification

1. Fractional `min_samples` values are in-domain public API inputs for OPTICS.
2. A fractional size is a fraction of the sample count and must become an
   integer sample count before it is used where an integer count is required.
3. The converted count is rounded and bounded below by 2.
4. `compute_optics_graph` must not pass a fractional float to
   `NearestNeighbors(n_neighbors=...)`.
5. `cluster_optics_xi` has the same fractional-size obligation for
   `min_samples` and `min_cluster_size`.
6. `compute_optics_graph` documentation must state that `min_samples` accepts
   a float fraction.

## Public Evidence Ledger

| ID | Source | Evidence | Obligation | Status |
| --- | --- | --- | --- | --- |
| IE1 | problem | `OPTICS(... min_samples=0.1).fit(data)` | Fractional `min_samples` is intended input. | Encoded |
| IE2 | problem | `min_samples = max(2, min_samples * n_samples) # Still a float` | Scaling alone is insufficient; type conversion is required. | Encoded |
| IE3 | problem | `NearestNeighbours class with a float it raises` | `n_neighbors` must receive an integer on this path. | Encoded |
| IE4 | problem | `int(round(max(2, min_samples * n_samples)))` and `round to get the closest integer` | The fractional conversion should use rounding, not truncation. | Encoded |
| IE5 | public hint | `maybe use int(...) directly?` | `int(...)` is needed to ensure Python integer type; this is weaker/ambiguous about rounding. | Considered |
| IE6 | public hint | `please fix similar issues in cluster_optics_xi` | Apply the same conversion to Xi `min_samples` and `min_cluster_size`. | Encoded |
| IE7 | public hint | `please update the doc of min_samples in compute_optics_graph` | Public docstring must mention float fractions. | Encoded |
| IE8 | source docstring | `fraction of the number of samples (rounded to be at least 2)` | Supports rounded integer count with lower bound 2. | Encoded |

## Formal Contract

Let `N = n_samples`, `S = size`, and assume `_validate_size(S, N, name)` has
accepted the value and the branch condition `S <= 1` holds. The in-domain
fractional branch has this postcondition:

```text
normalized_size = int(round(max(2, S * N)))
normalized_size is an integer count
normalized_size >= 2
```

For `compute_optics_graph`, that normalized value is the value passed as
`n_neighbors` to `NearestNeighbors` and as `min_samples` to
`_compute_core_distances_`.

For `cluster_optics_xi`, the normalized `min_samples` and `min_cluster_size`
values are the integer thresholds passed to `_xi_cluster`. If
`min_cluster_size is None`, it inherits the already-normalized `min_samples`.

Absolute integer counts greater than 1 are frame behavior for this fix: they
remain count values and are not reinterpreted as fractions.

## Formal Core

The K artifacts are:

- `fvk/mini-optics-size.k`
- `fvk/optics-size-spec.k`

They model the fractional branch as `normalizeFractional(SCALED)` reducing to
`roundPy(maxF(two, SCALED))`, where `roundPy` is sorted as `Int`. The exact
Python floating-point and tie-breaking semantics of `round` are a proof
capability boundary for this lightweight model; the code delegates those
details to Python's built-in `round`.

## Adequacy Audit

The formal English statement of the primary claim is:

> On the fractional branch, the program computes the scaled floating value,
> applies `max(2, ...)`, rounds it with Python's `round`, converts it with
> `int`, and uses that integer count downstream.

This matches IE2, IE3, IE4, IE6, and IE8. V1 failed this audit because it used
`int(size * n_samples)`, which truncates before applying the documented
rounding obligation. The V2 source change repairs that mismatch.

## Public Compatibility Audit

No public function signatures, return shapes, class attributes, or dispatch
protocols changed. The change is local to count normalization inside existing
functions. The `compute_optics_graph` docstring now matches the already
documented `OPTICS`/`cluster_optics_xi` fractional `min_samples` API.
