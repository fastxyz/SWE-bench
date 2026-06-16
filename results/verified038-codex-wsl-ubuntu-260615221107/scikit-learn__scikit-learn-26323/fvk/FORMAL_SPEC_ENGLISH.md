# Formal Spec English

Status: constructed, not machine-checked.

## Claim Paraphrases

`REMAINDER-PROPAGATED`

If a `ColumnTransformer` starts with an explicit child and an estimator-valued
remainder both using default output, then `set_output(pandas)` leaves the
explicit child, the remainder estimator, and the `ColumnTransformer` itself
pandas-configured.

`CLONED-REMAINDER-PANDAS`

After `set_output(pandas)` on a `ColumnTransformer` with an estimator-valued
remainder, the output configuration observed by the fit-time clone of the
remainder is pandas.

`PANDAS-HSTACK`

If the `ColumnTransformer` output config is pandas, the explicit child output
is pandas, and the cloned remainder output is pandas, dense `_hstack` takes the
pandas concatenation branch.

`SENTINEL-UNCHANGED`

If `remainder` is a string sentinel rather than an estimator, `set_output` does
not treat it as a child estimator. Explicit children and the
`ColumnTransformer` itself are still configured.

`NONE-NOOP`

If `transform=None`, output configuration propagation leaves child
configuration unchanged. The model still records that the
`ColumnTransformer`'s self-level output config is not changed by `None`.
