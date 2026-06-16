# Formal Spec English

This file paraphrases each nontrivial K claim in
`fvk/quantile-attrs-spec.k`.

## VQ-KEEP-TRUE

Starting from `variableQuantile(var(DIMS, DATA, ATTRS), Q, DIM, INTERP, true)`,
the result is `var(quantileDims(DIMS, Q, DIM), quantileData(DATA, Q, DIM,
INTERP), ATTRS)`. In plain English: `Variable.quantile(..., keep_attrs=True)`
preserves the original variable attrs while leaving numeric value and dimension
calculation to the existing quantile operation.

## VQ-KEEP-FALSE

Starting from `variableQuantile(..., false)`, the result variable has empty
attrs. In plain English: explicit `keep_attrs=False` continues to drop attrs.

## VQ-KEEP-DEFAULT-TRUE and VQ-KEEP-DEFAULT-FALSE

Starting from `variableQuantile(..., default)`, the result follows the global
keep_attrs option with default `False`. In plain English: `keep_attrs=None` is
not a third attrs behavior; it resolves to true or false through the existing
global option helper.

## DATASET-PASS-KEEP

Starting from a dataset whose data variable has attrs `ATTRS`,
`datasetQuantile(..., true)` returns a dataset whose corresponding reduced
variable has attrs `ATTRS`, and whose dataset attrs are also preserved. In
plain English: `Dataset.quantile` must pass the resolved keep flag into each
variable quantile call and retain its existing dataset-level attrs behavior.

## DATASET-PASS-DROP

Starting from the same dataset and `keep_attrs=False`, both the reduced
variable attrs and dataset attrs are empty. In plain English: explicit false
continues to drop attrs.

## DA-KEEP-TRUE

Starting from a `DataArray` whose underlying variable has attrs `ATTRS`,
`dataArrayQuantile(..., true)` returns a `DataArray` whose underlying result
variable has attrs `ATTRS`. In plain English: the reported MCVE must return the
original attrs when `keep_attrs=True`.

## DA-KEEP-FALSE

Starting from the same data array and `keep_attrs=False`, the result attrs are
empty. In plain English: the fix must not make attrs unconditional.
