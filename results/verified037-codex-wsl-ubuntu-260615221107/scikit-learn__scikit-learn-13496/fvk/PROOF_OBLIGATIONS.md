# Proof Obligations

Status: constructed, not machine-checked.

## PO1 - Public parameter exposure

`IsolationForest.__init__` must include `warm_start=False` as an explicit public
constructor parameter.

Evidence: E1, E3.

Discharged by: V2 signature in `repo/sklearn/ensemble/iforest.py`.

## PO2 - Inherited behavior pass-through

The `warm_start` constructor value must be passed to `BaseBagging.__init__` as
`warm_start=warm_start`.

Evidence: E2, E5.

Discharged by: V2 `super().__init__(..., warm_start=warm_start, ...)`.

## PO3 - Default behavior preservation

When `warm_start` is omitted, the constructed estimator must have
`warm_start=False`, so prior default fitting behavior is unchanged.

Evidence: E3, E5.

Discharged by: default argument `warm_start=False` and K claim
`IFOREST-DEFAULT-WARM-START`.

## PO4 - Positional compatibility

The new optional parameter must not shift old positional constructor arguments.

Evidence: E7.

Discharged by: V2 appends `warm_start` after `verbose`; K claim
`IFOREST-POSITIONAL-COMPAT`.

V1 status: failed. See Finding F1.

## PO5 - Documentation

The class docstring must document `warm_start` using the requested
RandomForest-style wording.

Evidence: E4, E6.

Discharged by: the new `warm_start` docstring block in
`repo/sklearn/ensemble/iforest.py`.

## PO6 - Test and execution constraints

No test files may be modified, and no tests, Python, or K commands may be run in
this environment.

Evidence: E8.

Discharged by: no test edits; proof commands are recorded but not executed.
