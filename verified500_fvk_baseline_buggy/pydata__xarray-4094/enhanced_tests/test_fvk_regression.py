import numpy as np

import xarray as xr


def test_to_unstacked_dataset_preserves_length1_dim():
    # Regression test: a to_stacked_array(...).to_unstacked_dataset(...) roundtrip
    # must preserve a legitimate length-1 sample dimension. The buggy
    # implementation used an unqualified ``.squeeze(drop=True)`` which silently
    # destroyed every size-1 dimension on each reconstructed variable, including
    # the real length-1 ``x`` dimension here, instead of dropping only the
    # stacked index dimension.
    arr = xr.DataArray(np.arange(1), coords=[("x", [0])])
    ds = xr.Dataset({"a": arr, "b": arr})

    stacked = ds.to_stacked_array("y", sample_dims=["x"])
    unstacked = stacked.to_unstacked_dataset("y")

    # the length-1 'x' dimension must survive on every reconstructed variable
    assert unstacked["a"].dims == ("x",)
    assert unstacked["b"].dims == ("x",)

    # and the full roundtrip must be lossless
    assert unstacked.identical(ds)
