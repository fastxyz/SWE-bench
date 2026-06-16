# Intent Spec

Status: constructed from public evidence only; current implementation behavior is
listed only as behavior to audit.

## Required behaviors

1. Boolean weights are in the supported domain for weighted reductions. They
   must behave as numeric 0/1 weights, not as boolean truth values.
2. `sum_of_weights` for a data array must sum the weights whose corresponding
   data values are non-null. For boolean weights this sum is an integer count of
   valid `True` weights.
3. Weighted mean is `weighted_sum / sum_of_weights`. For the reported input
   data `[1., 1., 1.]` and boolean weights `[True, True, False]`, the numerator
   is `2`, the denominator is `2`, and the mean is `1.0`.
4. Zero total weight remains invalid/missing for means, preserving the existing
   `sum_of_weights.where(sum_of_weights != 0.0)` behavior.
5. The public API shape must not change: `DataArray.weighted(weights)` and
   `Dataset.weighted(weights)` still accept a `DataArray` of weights and return
   the existing weighted helper objects.
6. The internal `_reduce` helper's documented equivalence to
   `(da * weights).sum(dim, skipna)` must hold for the boolean/boolean product
   case as well as the already-working numeric cases.

## Default-domain assumptions

- The formal model reasons after xarray alignment/broadcasting has selected the
  values participating in the reduction; in the model, lists therefore have the
  same length.
- The FVK pass proves partial correctness of the reduction equations, not
  termination or performance.
- The model represents the observable value axis that matters here: boolean
  truth reduction versus integer 0/1 summation.
