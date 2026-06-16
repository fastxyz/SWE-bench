# Iteration Guidance

Status: constructed, not machine-checked.

## Code Decision

V1 stands unchanged.

Reason: F-001 is resolved by PO-001, PO-002, PO-003, PO-004, and PO-006. The
current source places dtype coercion at `HuberRegressor.fit`'s validation
boundary, matching the public issue's requested behavior. No finding identifies
an unresolved production-code defect for the public `fit` path.

## Do Not Change

Do not add a cast inside `_huber_loss_and_gradient` for this issue. F-002 and
PO-007 classify direct boolean calls to the private helper as outside the
public contract, while adding a second cast would duplicate validation policy
inside a numerical helper.

Do not force `dtype=np.float64` for all floating input. PO-004 preserves
existing float dtype behavior by using `FLOAT_DTYPES`, matching local
scikit-learn validation conventions.

Do not edit tests in this benchmark task. F-004 is test guidance only.

## Future Work

If tests can be added in a normal development setting, add coverage for:

- `HuberRegressor().fit(X_bool, y)` where `X_bool` is dense boolean data;
- optionally, `HuberRegressor().fit(csr_matrix(X_bool), y)` for accepted sparse
  boolean data.

Before using the FVK proof to remove any dtype-specific test, run the commands
listed in `PROOF.md` and require `kprove` to return `#Top`.

If a later task asks for full Huber correctness, formalize the optimizer,
objective, convergence behavior, and output attributes separately. This FVK
pass intentionally proves only the dtype-safety slice that caused the reported
TypeError.
