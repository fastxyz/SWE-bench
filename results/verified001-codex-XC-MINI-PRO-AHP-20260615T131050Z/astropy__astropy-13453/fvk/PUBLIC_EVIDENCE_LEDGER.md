# Public Evidence Ledger

Status: constructed from allowed public inputs.

| ID | Source | Evidence | Semantic Obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | "When writing out an astropy table to HTML format, the `formats` option ... seems to be ignored." | HTML output must not ignore `formats`. | Encoded in O1. |
| E2 | `benchmark/PROBLEM.md` | "I expect the HTML table output to respect the formatting given by the `formats` argument." | A supplied format for a column must affect that column's HTML cell strings. | Encoded in O1 and O2. |
| E3 | `benchmark/PROBLEM.md` | CSV and RST examples render `1.238...e-24` as `1.24e-24` when `formats={"a": lambda ...}` is supplied. | HTML should use the same formatting path as other ASCII writers for data values. | Encoded in O2. |
| E4 | `repo/astropy/io/ascii/ui.py` | `formats : dict` is documented as a writer keyword. | The public writer API accepts format specifiers or formatting functions. | Encoded in O1. |
| E5 | `repo/astropy/io/ascii/core.py` | `BaseData.str_vals()` calls `_set_col_formats()` before `col.info.iter_str_vals()`. | Existing ASCII writer semantics install formats before value-to-string conversion. | Encoded in O2. |
| E6 | `repo/astropy/io/ascii/html.py` | HTML writer uses `col.info.iter_str_vals()` for cell text and has separate raw HTML and fill-value handling. | The fix should wire formats into the existing iterator path while preserving raw HTML and fill behavior. | Encoded in O3 and O4. |
| E7 | `repo/astropy/io/ascii/html.py` | HTML writer splits multidimensional columns into temporary `Column([el[i] for el in col])` objects when `multicol` is true. | A source-column format must be copied to temporary split columns before their iterators are built. | Encoded in O5. |

No hidden tests, internet sources, upstream patches, or evaluator outputs were
used.
