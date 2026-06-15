# Proof Obligations

Status: constructed, not machine-checked.

## O1 - Apply matching format entries

For every column `col` in the HTML writer's selected `cols`, if
`col.info.name in self.data.formats`, then before any data-cell iterator is
created, `col.info.format == self.data.formats[col.info.name]`.

Discharged by V1:

- `self.data.cols = cols`
- `self.data._set_col_formats()`

## O2 - Use the standard Astropy formatting iterator

After O1, HTML cell strings for a one-dimensional column are obtained from
`col.info.iter_str_vals()`, so callable and string format semantics remain the
standard Astropy semantics instead of a new HTML-only formatter.

Discharged by existing code plus O1:

- one-dimensional path uses `col.info.iter_str_vals()`
- O1 ensures `info.format` is installed first

## O3 - Preserve columns without format entries

If a column name is absent from `self.data.formats`, `_set_col_formats()` does
not modify that column's `info.format`.

Discharged by existing `BaseData._set_col_formats()` branch condition:

- `if col.info.name in self.formats: col.info.format = ...`

## O4 - Preserve fill-value and raw-HTML frame behavior

Formatting must not bypass existing HTML downstream behavior: fill-value
replacement remains wrapped around the string iterator, and raw HTML columns
still choose the existing escape or bleach-cleaning method.

Discharged by V1 leaving these calls and branches unchanged:

- `self.fill_values(col, col.info.iter_str_vals())`
- `method = ('escape_xml' if col_escaped else 'bleach_clean')`

## O5 - Preserve formats through multicolumn splitting

For every source column split into temporary subcolumns, the temporary column
must receive the source column's active `info.format` before its iterator is
created.

Discharged by V1:

- `new_col.info.format = col.info.format`
- followed by `new_col.info.iter_str_vals()`

## O6 - Public compatibility

The fix must not alter public writer signatures, registry names, return shape,
or callsite protocol.

Discharged by source audit:

- no signature or registration changes
- `HTML.write(table)` still returns `[''.join(lines)]`

## O7 - Honesty gate

The proof must be labeled constructed, not machine-checked, and test removal
must remain conditional on running K tooling in a suitable environment.

Discharged by artifact labels and `PROOF.md` run-command section.
