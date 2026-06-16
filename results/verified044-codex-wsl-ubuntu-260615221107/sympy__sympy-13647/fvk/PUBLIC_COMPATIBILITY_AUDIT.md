# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed public symbols

No public symbol signature was changed. V1 edits only the internal entry mapping
inside `MatrixShaping._eval_col_insert`.

## Dispatch and overrides

`MatrixShaping.col_insert(pos, other)` still calls
`self._eval_col_insert(pos, other)` with the same two arguments. Existing
overrides are not forced to accept new parameters or return a new protocol.

Observed related implementation:

- `SparseMatrix._eval_col_insert(self, icol, other)` already implements the
  compatible behavior by shifting existing columns by `other.cols`.

## Producer/consumer shape

The result construction still uses `_new(self.rows, self.cols + other.cols,
entry_function)`. Consumers continue to see the same matrix type protocol and
the same result dimensions.

## Conclusion

No compatibility blocker was found. The audit supports keeping V1 unchanged
with respect to public API and dispatch behavior.
