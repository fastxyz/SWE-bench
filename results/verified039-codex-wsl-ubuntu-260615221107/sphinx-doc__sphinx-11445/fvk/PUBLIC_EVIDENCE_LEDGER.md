# PUBLIC EVIDENCE LEDGER

| ID | Source | Quote or local evidence | Semantic obligation |
| --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | "Using rst_prolog removes top level headings containing a domain directive" | The fix must preserve top-level headings containing inline domain roles when `rst_prolog` is set. |
| E2 | `benchmark/PROBLEM.md` | `:mod:`mypackage2`` followed by `=================` | This concrete role-heading shape is in domain. |
| E3 | `benchmark/PROBLEM.md` hint | "the prolog is inserted between `:mod:`...` and the header definition" | The insertion point must not lie between the title line and underline. |
| E4 | `repo/doc/usage/configuration.rst` | `rst_prolog` is "included at the beginning of every source file" | Prolog precedes ordinary non-docinfo content. |
| E5 | `repo/doc/usage/restructuredtext/field-lists.rst` | "A field list near the top of a file is normally parsed by docutils as the docinfo" | Genuine leading docinfo remains before prolog. |
| E6 | `repo/doc/usage/restructuredtext/basics.rst` | Section headers are created by underlining with a punctuation character "at least as long as the text" | A title-aware guard may identify the title/underline pair before deciding docinfo status. |
| E7 | `repo/tests/test_util_rst.py` | Existing public tests assert prolog-at-start and prolog-after-docinfo line order | These support compatibility frame conditions, but not the buggy role-title behavior. |

