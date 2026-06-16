# Intent Spec

Status: constructed from public evidence only. The current implementation is treated as the candidate to check, not as the specification.

## Required behaviors

I-001. `Dataset.swap_dims()` returns a new dataset-like object with swapped dimensions.

I-002. For each valid dimension mapping `old_dim -> new_dim`, every variable in the returned dataset has each occurrence of `old_dim` in its dimension tuple replaced by `new_dim`.

I-003. If `new_dim` names an existing 1D variable along `old_dim`, that variable becomes the dimension coordinate/index variable in the returned dataset.

I-004. Calling `swap_dims()` must not mutate the input dataset or the variable metadata stored on that input dataset. In particular, a data variable promoted to a dimension coordinate in the result must not have its `.dims` changed on the original object.

I-005. Existing validation remains part of the public contract: swapping from a non-existing dimension raises `ValueError`; replacing with an existing variable that is not 1D along the old dimension raises `ValueError`.

I-006. No public API signature, dispatch shape, or return-type family is changed by this fix.

## Domain

The in-domain behavior for this audit is a call to `Dataset.swap_dims()` after the method's public validation succeeds:

- every key in `dims_dict` is an existing dimension;
- if a replacement name is also an existing variable, that variable has dimensions exactly `(old_dim,)`.

Out-of-domain error behavior is covered only as a frame condition: V1 did not change the existing validation branches.

## Default-domain assumptions

- Python object identity and field assignment are modeled normally: assigning `var.dims = ...` mutates the variable object referenced by `var`.
- xarray variables may share underlying array/index data in shallow-copying transformations, but object metadata ownership must be sufficient to preserve the input object's observable metadata.
- `IndexVariable.copy(deep=False)` returns a distinct `IndexVariable` object with equivalent data/attrs/encoding metadata, sharing immutable pandas-backed data where appropriate.
