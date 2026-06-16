# Intent Spec

This file records public intent before accepting candidate implementation
behavior.

1. `LogisticRegressionCV(..., refit=False).fit(X, y)` must not raise the
   reported `IndexError` for valid binary data using default
   `multi_class='auto'`.
2. The same no-refit auto-to-OvR behavior must hold for `solver='liblinear'`,
   because public issue text says the same error appears there and the
   docstring says `auto` selects OvR for liblinear.
3. Branching on coefficient-path shape must follow the effective multiclass
   strategy: OvR uses per-class three-axis paths, multinomial uses paths with a
   class axis.
4. Non-elastic-net fits must not attempt to compute a numeric l1-ratio mean;
   absence of an active l1-ratio is represented as `None`.
5. Supplying `l1_ratios` with a non-elastic-net penalty is ignored after a
   warning and must not alter elastic-net-specific public attribute shapes.
6. Public constructor signatures and estimator parameters must remain
   compatible.
