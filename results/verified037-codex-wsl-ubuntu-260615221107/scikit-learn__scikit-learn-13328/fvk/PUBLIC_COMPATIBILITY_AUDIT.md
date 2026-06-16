# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed Public Symbols

None. V1 does not change the signature or public name of
`HuberRegressor.fit`.

## Changed Internal Calls

`HuberRegressor.fit` now calls:

```python
check_X_y(X, y, copy=False, accept_sparse=['csr'], y_numeric=True,
          dtype=FLOAT_DTYPES)
```

instead of the same call without the `dtype` keyword.

Compatibility status: pass.

Reason: `check_X_y` already has a public `dtype` keyword with documented
behavior. The call is internal to `HuberRegressor.fit`, and no subclass or
override dispatch is involved.

## Producer/Consumer Shape

Producer: `check_X_y` returns validated `(X, y)`.

Consumer: `optimize.fmin_l_bfgs_b` receives `_huber_loss_and_gradient` with the
validated `X`.

Compatibility status: pass.

Reason: V1 changes only the dtype of non-floating numeric `X` to a floating
dtype. Shape, sparse CSR acceptance, target handling, sample-weight handling,
and optimizer argument order are unchanged.

## Private Helper Boundary

`_huber_loss_and_gradient` remains a private helper. This audit treats its
precondition as: `X` has already passed the public `fit` validation path. No
public API compatibility obligation requires direct boolean input support for
that helper.
