# Intent Specification

Status: constructed from public intent, not machine-checked.

## Required Behavior

1. `Table.write(..., format="html", formats={name: format_spec})` must use
   the supplied `formats` entry when rendering every HTML data cell belonging
   to column `name`.

2. The HTML writer must have the same `formats` semantics as the other ASCII
   writers for the same table values: a callable or string format is installed
   on the selected column before `col.info.iter_str_vals()` converts values to
   strings.

3. Columns without an entry in `formats` must retain their existing formatting
   behavior.

4. Existing HTML writer behavior outside value-string formatting must be
   preserved: fill-value replacement still occurs, raw HTML columns still use
   the existing escaping or cleaning path, and the public `HTML.write(table)`
   method signature is unchanged.

5. Because the HTML writer explicitly supports multidimensional columns by
   splitting them into multiple HTML cells, a `formats` entry for the source
   column must also apply to each temporary split column.

## Domain

The contract covers HTML writing for table columns accepted by
`HTML._check_multidim_table(table)`, with `formats` keys that correspond to
column names after the public `ascii.write` validation step. The actual Python
format callable or format string is treated as an opaque formatter already
handled by Astropy's `col.info.iter_str_vals()` machinery.

## Out Of Scope For This FVK Pass

The pass does not specify the complete HTML serialization grammar, BeautifulSoup
reading behavior, or the full semantics of arbitrary Python formatter callables.
Those are preserved as trusted Astropy/library behavior; the proof obligation is
that the HTML writer installs the intended column format before delegating to
that existing machinery.
