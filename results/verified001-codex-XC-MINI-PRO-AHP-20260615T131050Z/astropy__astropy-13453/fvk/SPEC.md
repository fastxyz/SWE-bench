# FVK Specification

Status: constructed, not machine-checked.

## Target

Target source: `repo/astropy/io/ascii/html.py`, method `HTML.write(table)`.

The verified slice is the HTML writer's value-formatting pipeline. The mini-K
model abstracts full Python and full HTML generation, but it preserves the
observable property under audit: whether a `formats` entry is installed before
cell strings are produced.

## Public Intent Ledger

The ledger is mirrored in `PUBLIC_EVIDENCE_LEDGER.md`.

- E1 and E2 from `benchmark/PROBLEM.md`: HTML output must respect the
  `formats` argument.
- E3 from `benchmark/PROBLEM.md`: CSV and RST demonstrate the intended ASCII
  writer behavior for the same format dictionary.
- E4 from `repo/astropy/io/ascii/ui.py`: `formats` is a public writer keyword.
- E5 from `repo/astropy/io/ascii/core.py`: other ASCII writers call
  `_set_col_formats()` before `iter_str_vals()`.
- E6 from `repo/astropy/io/ascii/html.py`: HTML already delegates data string
  rendering to `col.info.iter_str_vals()`.
- E7 from `repo/astropy/io/ascii/html.py`: HTML multicolumn rendering creates
  temporary split columns, so format propagation must reach those objects too.

## Contract

For every accepted table column rendered by the HTML writer:

1. If `formats` contains the column name, the column's `info.format` is set to
   that entry before `info.iter_str_vals()` is evaluated.
2. If `formats` does not contain the column name, the column's existing
   `info.format` is preserved.
3. If the column is split into temporary multicolumn subcolumns, each temporary
   column receives the source column's current `info.format` before its
   `info.iter_str_vals()` iterator is evaluated.
4. Fill-value replacement and raw HTML escaping/cleaning remain downstream of
   string rendering and are not otherwise changed.

## Preconditions

- The table passes the existing HTML dimensionality check.
- `formats` is the writer data map provided by the existing ASCII writer setup.
- Formatter semantics are delegated to `col.info.iter_str_vals()`; this proof
  does not reimplement arbitrary Python callable or format-string behavior.

## Claims

- `HTML-FORMATS-1D`: format map entries are applied before one-dimensional cell
  iterators are constructed.
- `HTML-FORMATS-NO-ENTRY`: absent format entries preserve previous column
  formatting.
- `HTML-FORMATS-MULTICOL`: split temporary columns inherit the source column
  format before their iterators are constructed.

Formal claim sketches are in `html-format-spec.k`.
