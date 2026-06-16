# Proof Obligations

Status: all obligations discharged by constructed reasoning, not machine-checked.

| ID | Obligation | Evidence | Status |
| --- | --- | --- | --- |
| PO-1 | `Paginator` has an `__iter__` method. | E-001 | Discharged by V1 source: `def __iter__(self):`. |
| PO-2 | Iteration traverses the whole `page_range`. | E-002, E-003, E-005 | Discharged by claim `ITER-PAGES` and source loop `for page_number in self.page_range`. |
| PO-3 | Iteration yields `self.page(page_number)`, not raw page numbers. | E-003, E-004 | Discharged by claim `YIELD-PAGES` and source `yield self.page(page_number)`. |
| PO-4 | Yield order matches `page_range` order. | E-003, E-005 | Discharged by `YIELD-PAGES`: head page is emitted before recursion on the tail. |
| PO-5 | Empty `page_range` yields no pages. | E-005, I-005 | Discharged by the empty-list branch of `YIELD-PAGES`. |
| PO-6 | A one-element `page_range` yields exactly one page. | E-003, E-004, I-005 | Discharged by the non-empty branch followed by the empty branch. |
| PO-7 | Existing `page()` and `_get_page()` customization are preserved. | E-006, E-007 | Discharged by source call to `self.page(...)`; no direct `Page(...)` construction in `__iter__`. |
| PO-8 | No unrelated public API or behavior is changed. | I-005, C-001 through C-004 | Discharged by the source diff: only `Paginator.__iter__()` was added, with no changes to existing methods or signatures. |

## Constructed proof commands

The following commands are recorded for later machine checking and were not executed:

```sh
kompile fvk/mini-python-paginator.k --backend haskell
kast --backend haskell fvk/paginator-iter-spec.k
kprove fvk/paginator-iter-spec.k
```

Expected machine-check result after any syntax adjustments required by a local K installation: `#Top` for claims `ITER-PAGES` and `YIELD-PAGES`.
