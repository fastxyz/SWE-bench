# Public Evidence Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E-001 | `benchmark/PROBLEM.md` | "Paginator just implement the __iter__ function" | Add `Paginator.__iter__` as the public behavior change. | Encoded by PO-1 and claim `ITER-PAGES`. |
| E-002 | `benchmark/PROBLEM.md` | "iter into all the pages of a Paginator object" | Iteration covers every page in the paginator's page range. | Encoded by PO-2 and claim `YIELD-PAGES`. |
| E-003 | `benchmark/PROBLEM.md` | Proposed method loops `for page_num in self.page_range` and yields `self.page(page_num)`. | Yield `Page` values, in `page_range` order, via the public `page()` method. | Encoded by PO-2, PO-3, PO-4. |
| E-004 | `repo/docs/ref/paginator.txt` | `Paginator.page(number)` "Returns a Page object with the given 1-based index." | The object yielded for a page number is the result of `page(number)`. | Encoded by PO-3. |
| E-005 | `repo/docs/ref/paginator.txt` | `Paginator.page_range` is "A 1-based range iterator of page numbers". | `page_range` supplies the ordered page-number sequence used by iteration. | Encoded by PO-2 and PO-5. |
| E-006 | `repo/django/core/paginator.py` | `_get_page()` docstring says it is a subclass hook for alternative `Page` objects. | Iteration must preserve subclass page construction by calling `self.page()`. | Encoded by PO-4 and public compatibility audit C-002. |
| E-007 | `repo/tests/pagination/custom.py` and `repo/tests/pagination/tests.py` | `ValidAdjacentNumsPaginator` overrides `_get_page()` and tests page instances returned through `page()`. | Public subclass hook behavior is compatibility-relevant. | Encoded by PO-4 and C-002. |
| E-008 | `reports/baseline_notes.md` | V1 added `for page_number in self.page_range: yield self.page(page_number)`. | Candidate implementation to audit against the public intent, not independent intent evidence. | Checked by F-001 through F-004. |
