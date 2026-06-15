# Public Compatibility Audit

Status: static audit only; no code executed.

## Changed Symbol

`repo/astropy/io/fits/card.py`: `Card._split()`

Change:

- `_strg_comment_RE.match(vc)` -> `_strg_comment_RE.fullmatch(vc)`
- removed per-chunk `replace("''", "'")`

## Public API Compatibility

| Surface | Status | Reason |
| --- | --- | --- |
| `Card.fromstring(image)` signature | Unchanged | V1 edits only internal parsing inside `_split()`. |
| `Card.value` property | Unchanged API, corrected value | The property still calls `_parse_value()`; V1 changes the escaped text fed to it. |
| `Card.comment` property | Unchanged | Comment collection and parsing path is preserved. |
| `Header.fromstring(data)` grouping | Unchanged | Header grouping of physical `CONTINUE` cards is untouched. |
| `Header.tostring()` / card stringification | Unchanged formatting | `_format_long_image()` is untouched. |
| Public tests | Unchanged | No files under `repo/astropy/io/fits/tests/` were edited. |

## Static Callsite Check

`_strg_comment_RE` is only used in `Card._split()`. `_split()` is consumed by
`_parse_value()`, `_parse_comment()`, `_fix_value()`, and verification helpers.
All retain the same return shape: `(keyword, valuecomment)`.

## Result

No compatibility blocker was found. This supports F3 and PO7.
