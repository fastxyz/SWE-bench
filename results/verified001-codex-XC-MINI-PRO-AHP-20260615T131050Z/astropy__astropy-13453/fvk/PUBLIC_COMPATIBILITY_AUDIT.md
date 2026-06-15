# Public Compatibility Audit

Status: source audit, no code execution.

## Changed Public Symbols

None. V1 edits only the body of `astropy.io.ascii.html.HTML.write`; it does not
change public function names, method signatures, return types, module imports,
or registered I/O format names.

## Public Callers And Overrides

- `Table.write(..., format="html")` continues to route through the existing
  ASCII writer registry and `HTML.write(table)`.
- `astropy.table.jsviewer.write_table_jsviewer` continues to pass `htmldict`
  options to HTML writing; V1 does not alter that producer/consumer shape.
- Direct in-repo uses of `html.HTML().write(table)` still receive a list with
  one HTML string, as before.
- No subclass override of `HTML.write` was found in the allowed source search.

## Compatibility Result

Pass. The fix is an internal ordering/context repair: it connects
`writer.data.formats` to the columns that `HTML.write` already renders. Public
dispatch and output container shape are unchanged.
