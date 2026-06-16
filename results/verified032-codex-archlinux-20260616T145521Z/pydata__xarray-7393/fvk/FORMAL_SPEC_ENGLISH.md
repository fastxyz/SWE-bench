# Formal Spec English

Status: constructed, not machine-checked.

This file paraphrases the K claims in
`pandas-multi-indexing-adapter-spec.k`.

## Claim MI-ARRAY-DEFAULT-LEVEL-DTYPE

For any MultiIndex adapter with a named level, if `__array__` is called without
an explicit dtype and the pandas level values are castable to the adapter's
stored dtype, the result is an ndarray containing those level values cast to the
adapter's stored dtype. The result dtype is the adapter's stored dtype, even if
pandas materialized the level values with a different dtype.

## Claim MI-ARRAY-EXPLICIT-DTYPE

For any MultiIndex adapter with a named level, if `__array__` is called with an
explicit dtype and the pandas level values are castable to that dtype, the
result is an ndarray containing those level values cast to the explicit dtype.
The explicit dtype overrides the adapter's stored dtype.

## Claim STACKED-LEVEL-VALUES-DTYPE

For a level coordinate adapter produced from an original coordinate dtype, a
default `.values` conversion returns an ndarray whose dtype equals that original
coordinate dtype. This is the issue's `int32` example generalized to all
castable level values.

## Claim MI-ARRAY-NONLEVEL-DELEGATES

For a `PandasMultiIndexingAdapter` whose `level` is absent, `__array__` delegates
to the base pandas index adapter using the same effective dtype rule. The V1
patch must not alter the aggregate MultiIndex coordinate conversion path beyond
the same dtype defaulting the base class already applies.

## Side Conditions

S1. Values are in scope only when pandas can materialize the requested level.

S2. Values are in scope only when NumPy can cast the materialized level values
to the effective dtype.

S3. The proof is partial correctness over the method result and does not prove
termination, pandas internals, or NumPy's cast implementation.

