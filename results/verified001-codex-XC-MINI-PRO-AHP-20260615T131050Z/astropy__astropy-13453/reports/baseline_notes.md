# Baseline Notes

## Root Cause

The `formats` keyword is passed into ASCII writers through `writer.data.formats`.
For the standard text writers, `BaseData.str_vals()` calls
`BaseData._set_col_formats()` before iterating over `col.info.iter_str_vals()`,
so user-provided formats are installed on the selected table columns.

The HTML writer overrides `BaseReader.write()` and builds its own HTML cell
iterators directly from `col.info.iter_str_vals()`. It did set up fill-value
handling, but it never set `self.data.cols` or called `_set_col_formats()`.
As a result, the `formats` dictionary remained stored on the writer but was
never applied to the columns used for HTML output.

## Changed Files

`repo/astropy/io/ascii/html.py`

- Set `self.data.cols` to the columns being written so the existing
  `BaseData._set_col_formats()` helper has the same column context it has in
  the generic writer path.
- Called `self.data._set_col_formats()` before HTML cell iterators are created,
  allowing `col.info.iter_str_vals()` to honor the user-supplied `formats`
  entries.
- Copied `col.info.format` onto temporary split columns used for HTML
  multicolumn output, so a format applied to a multidimensional source column is
  preserved when that column is rendered as multiple HTML cells.

## Assumptions and Alternatives

I assumed that HTML output should use the same `formats` semantics as the other
ASCII writers because the public `write(..., formats=...)` API validates the
keys for all ASCII formats and the HTML writer already relies on
`col.info.iter_str_vals()` for converting values to strings.

I considered formatting HTML cell values ad hoc inside `HTML.write()`, but
rejected that because Astropy already centralizes column formatting in
`BaseData._set_col_formats()` and `col.info.iter_str_vals()`. Reusing those
paths keeps callable formats, string formats, existing column formats, and
fill-value replacement behavior aligned with other ASCII outputs.

I also considered only applying formats for one-dimensional columns, which is
enough for the reported reproducer. I rejected that narrower behavior because
the HTML writer explicitly supports multidimensional columns, and its temporary
split columns would otherwise lose a format that had just been applied to the
source column.
