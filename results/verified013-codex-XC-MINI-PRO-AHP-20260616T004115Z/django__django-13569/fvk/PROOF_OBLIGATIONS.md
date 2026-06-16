# Proof Obligations

Status: constructed, not machine-checked.

## PO1: Random Orderings Are Excluded

For any non-reference order entry whose group-by column has:

- `contains_column_references = false`;
- no flattened `RawSQL` source;
- no flattened source with non-empty external columns;

the order-by grouping pass does not append that column.

Intent trace: E1, E2, E4. Claim: `DROP-RANDOM`.

## PO2: Direct Column Orderings Are Included

For any non-reference order entry whose group-by column has
`contains_column_references = true`, the order-by grouping pass appends that
column.

Intent trace: E3. Claim: `KEEP-COLUMN`.

## PO3: Raw SQL Orderings Are Included

For any non-reference order entry whose group-by column has a flattened
`RawSQL` source, the order-by grouping pass appends that column, even if direct
column-reference metadata is false.

Intent trace: E5. Claim: `KEEP-RAWSQL`.

## PO4: Subquery External-Column Orderings Are Included

For any non-reference order entry whose group-by column has a flattened source
with non-empty `get_external_cols()`, the order-by grouping pass appends that
column, even if direct column-reference metadata is false.

Intent trace: E3, E7. Claim: `KEEP-EXTERNAL-COLS`.

## PO5: Reference Orderings Are Skipped

For any order entry with `is_ref = true`, the order-by grouping pass appends no
additional grouping expression from that entry.

Intent trace: E6. Claim: `DROP-REF`.

## PO6: Finite List Preservation

For a finite `order_by` list, the pass processes entries in order. The output is
the concatenation of the kept group-by columns from each non-reference entry.
No other code path in `get_group_by()` is changed.

Intent trace: E2-E7. Claim family: recursive `orderGroupCols()` rules plus
`FILTER-STEP`.

## PO7: Frame Conditions

The patch must not change:

- grouping expressions from `select`;
- grouping expressions from `HAVING`;
- `collapse_group_by()`;
- SQL compilation and formatting;
- method signatures or return shape.

Intent trace: compatibility audit. Evidence: source diff only changes the
order-by append filter.
