# FVK Proof Obligations

Status: constructed, not machine-checked.

## PO-001: Plain Structured Ndarray Uses ColumnClass

Precondition:

- `data` is a `numpy.ndarray` or ndarray subclass with structured dtype.
- `data` is not an `astropy.table.Column`.
- `_is_mixin_for_table(data)` is false.
- `get_mixin_handler(data)` is `None`.
- The first element is not a table mixin.

Postcondition:

- `_convert_data_to_col` does not view `data` as `NdarrayMixin`.
- Control reaches the existing `col_cls = self.ColumnClass` path and constructs
  `col_cls(name=name, data=data, dtype=dtype, copy=copy, ...)`.

Evidence: SPEC E1-E4. Formal claim: C1.

Status: discharged by V2 source inspection and the constructed K claim.

## PO-002: Structured Dtype And Values Are Preserved By Existing Column Path

Precondition:

- PO-001 holds.
- No explicit `dtype` override contradicts the source data.

Postcondition:

- The existing `BaseColumn.__new__` path uses `np.array(data, dtype=dtype,
  copy=copy)` and views the result as the target column class, preserving the
  structured dtype and values for normal construction.

Evidence: `repo/astropy/table/column.py` existing constructor logic and the
issue's statement that structured columns now work.

Status: discharged by existing source behavior; no V2 edit needed.

## PO-003: Explicit NdarrayMixin Inputs Remain Mixins

Precondition:

- `data` is already a valid table mixin, such as a user-created
  `NdarrayMixin`.

Postcondition:

- `_is_mixin_for_table(data)` is true.
- `_convert_data_to_col` returns through the `data_is_mixin` branch, preserving
  explicit mixin behavior.

Evidence: SPEC I4. Formal claim: C2.

Status: discharged by unchanged source lines 1218 and 1261-1266.

## PO-004: Public NdarrayMixin Export Remains Available

Precondition:

- `astropy.table.__init__` imports `NdarrayMixin` from `.table`.

Postcondition:

- `astropy.table.table` still binds `NdarrayMixin`.

Evidence: SPEC E5, FINDINGS F-001. Formal claim: C3.

Status: failed in V1, discharged in V2 by restoring the import-only binding with
`# noqa: F401`.

## PO-005: Suspect Legacy Test Does Not Override Intent

Precondition:

- A public in-repo test asserts the old behavior that the issue identifies as
  undesirable.

Postcondition:

- The production code follows the public issue/hint intent, and the test is
  classified as SUSPECT legacy evidence rather than a correctness oracle.

Evidence: SPEC E6, FINDINGS F-002.

Status: discharged by not modifying production code to satisfy the suspect
assertions and not editing tests under the task constraints.

## PO-006: Honesty Gate

Precondition:

- This workspace has no execution environment for tests, Python, or K tooling.

Postcondition:

- Artifacts record exact commands and expected proof outcome, but no command is
  claimed to have run.

Status: discharged by artifact wording and command non-execution.
