# Formal Spec English

Status: constructed, not machine-checked.

The K model abstracts the order-by grouping pass to a finite list transformer
named `orderGroupCols`.

`DROP-RANDOM`: For a non-reference order entry whose only grouping expression
has no column references, no raw SQL source, and no external columns, the output
grouping list is empty.

`KEEP-COLUMN`: For a non-reference order entry whose grouping expression has
`contains_column_references = true`, that grouping expression appears in the
output grouping list.

`KEEP-RAWSQL`: For a non-reference order entry whose grouping expression has no
column references but has a flattened `RawSQL` source, that grouping expression
appears in the output grouping list.

`KEEP-EXTERNAL-COLS`: For a non-reference order entry whose grouping expression
has no direct column-reference metadata but has a flattened source exposing
non-empty external columns, that grouping expression appears in the output
grouping list.

`DROP-REF`: For a reference order entry, the order-by grouping pass contributes
no additional grouping expression because the selected expression is already
accounted for by the select grouping path.

`FILTER-STEP`: For a finite list of order entries, processing one entry either
appends its retained grouping expressions or skips it, then recursively processes
the remaining entries in order.
