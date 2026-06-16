# Public Evidence Ledger

| ID | Source | Quoted Evidence | Semantic Obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt/issue | "Symlinked directories not collected since pytest 6.1.0" | This is a collection regression, not an intended skip. | Encoded by PO1 and K claim `VISIT-SYMLINK-DIR`. |
| E2 | prompt/issue | "a symlink to a directory in a test directory ... should be followed and collected as usual" | A symlink whose target is a directory must be treated as a directory for recursion. | Encoded by PO1. |
| E3 | prompt/issue | "`follow_symlinks=False` ... does not match the previous behavior and should be removed" | The traversal predicate must not pass `follow_symlinks=False`. | Encoded by PO1 and source audit. |
| E4 | source | `if entry.is_dir() and recurse(entry): yield from visit(entry.path, recurse)` | The V1 candidate follows symlink directories and still gates recursion on `recurse(entry)`. | Implementation fact used for proof, not intent by itself. |
| E5 | source | `_recurse` checks `__pycache__`, `pytest_ignore_collect`, and `norecursedirs`. | Symlink traversal must continue to respect existing collection filters. | Encoded by PO3. |
| E6 | docs | "symlinks are no longer resolved during collection" | Following a symlink for traversal must not resolve reported/collected paths to real paths. | Encoded by PO4. |
| E7 | public test | `assert request.node.nodeid == "symlink.py::test_nodeid"` | Symlink spelling is an observable path property for collection. | Encoded by PO4. |
| E8 | source/public test | package collection comments skip broken symlinks; `test_collect_sub_with_symlinks` includes a broken symlink. | Broken symlinks are yielded/ignored as entries but are not traversal roots. | Encoded by PO5. |

