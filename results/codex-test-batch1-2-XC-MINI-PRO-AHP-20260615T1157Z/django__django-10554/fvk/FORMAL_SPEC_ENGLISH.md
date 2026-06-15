# Formal Spec English

Status: constructed, not machine-checked.

## Claim: ORDERED-UNION-DERIVED-VALUES-FRAME

Initial state:

- `orig` is an ordered combined query whose order position is `4`.
- `orig` has two component queries, `c1` and `c2`.
- both component queries have selected column width `4`.

Execution:

- derive a `values_list('pk')`-style query from `orig`;
- the derived query and its derived component queries may have selected column
  width `1`;
- then check whether `orig` is still orderable.

Expected final state:

- the original query `orig` still refers to `c1` and `c2`;
- `c1` and `c2` still have selected column width `4`;
- the derived query refers to separate component queries `d1` and `d2`;
- `d1` and `d2` may have selected column width `1`;
- `assertOrderable(orig)` succeeds and the status remains `ok`.

## Negative discriminator

If cloning a combined query keeps the original component query references, then
the same derived `values_list('pk')` operation can narrow `c1` and `c2` to width
`1`. In that state `orig` still orders by position `4`, but its components no
longer select that position, so the model reaches `error`.
