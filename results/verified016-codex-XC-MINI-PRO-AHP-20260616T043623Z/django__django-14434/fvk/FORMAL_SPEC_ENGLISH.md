# Formal Spec English

Status: paraphrase of `fvk/schema-unique-spec.k`.

C-001, `UNIQUE-EXPLICIT-REFERENCES-COLUMN`

For any table name `T` and non-empty column list whose first member is `C`, a V2 explicit-name unique statement stores `raw(T)` in its columns reference. Asking the statement whether it references `raw(T), C` returns true.

C-002, `UNIQUE-GENERATED-REFERENCES-COLUMN`

For any table name `T` and non-empty column list whose first member is `C`, a V2 generated-name unique statement also returns true for `references_column(raw(T), C)`. Both the generated name part and the columns part use raw table keys, so the result is true.

C-003, `V1-EXPLICIT-COUNTEREXAMPLE`

For the same explicit-name input shape, the V1 construction used `wrapped(T)` inside the columns part. Since `wrapped(T)` is not equal to `raw(T)`, and the explicit name part has no reference behavior, `references_column(raw(T), C)` returns false.

C-004, `V2-RENDERS-TABLE-WITH-RAW-KEY`

The V2 statement's renderable table part contains the raw table key `raw(T)`. In source code that corresponds to wrapping the raw name at the SQL-placeholder boundary with `Table(table, self.quote_name)`, not storing a `Table` object in `Columns`.

