# Iteration Guidance

Status: constructed, not machine-checked.

## V2 Decision

V1 stands unchanged. The FVK audit found that the implemented source change
discharges PO-1 and PO-2, which are the obligations tied to the reported
FeatureUnion length mismatch. No production source edit is justified by the
current public intent.

## Recommended Follow-Up Tests

Do not edit tests in this task. For maintainers, the next public tests should
cover:

- `_wrap_in_pandas_container(existing_dataframe, columns=new_columns,
  index=different_length_index)` preserves the existing DataFrame index and
  updates columns.
- `FeatureUnion` with pandas output where the union result has fewer rows than
  the original input does not raise from index assignment.
- `ColumnTransformer` with pandas output and reduced-row DataFrame branch output
  follows the same preservation rule.

## Open Questions

- Should direct pandas `Series` output be treated as a pandas object with its own
  index, or should it remain on the generic non-DataFrame constructor path? The
  current public issue does not require answering this.

## Machine-Check Later

The proof commands in `PROOF.md` should be run in a K-enabled environment before
claiming machine-checked proof or removing any tests.
