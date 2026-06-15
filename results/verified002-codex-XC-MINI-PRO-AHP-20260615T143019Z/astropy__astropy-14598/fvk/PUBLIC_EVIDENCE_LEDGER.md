# Public Evidence Ledger

| ID | Source | Evidence | Obligation |
| --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | `Card.fromstring(str(card1))  # Should be the same as card1` | Round-trip value preservation. |
| E2 | `benchmark/PROBLEM.md` | Values ending in `''` sometimes become values ending in `'`. | Preserve logical doubled single quotes. |
| E3 | `benchmark/PROBLEM.md` | `"x"*100 + "'' aaa"` loses text after quotes. | Full parsing must preserve text after doubled quotes and spaces. |
| E4 | `repo/docs/io/fits/usage/headers.rst` | `CONTINUE` cards are automatic for long string values. | Long string values are in-domain. |
| E5 | `repo/docs/io/fits/usage/headers.rst` | The `CONTINUE` ampersand is not part of the string value. | Remove only the representation marker. |
| E6 | `repo/astropy/io/fits/card.py` | `_strg_comment_RE` is for `CONTINUE` string plus optional comment. | Parse a full string/comment field. |
| E7 | `repo/astropy/io/fits/card.py` | `_format_long_image()` escapes `'` as `''` before chunking. | Reassembly should operate on escaped payload text. |
| E8 | `repo/astropy/io/fits/tests/test_header.py` | Public tests cover long values and long comments. | Preserve comment behavior and representation frame. |

Pre-fix outputs shown in the issue are marked SUSPECT because the issue reports
them as wrong behavior.
