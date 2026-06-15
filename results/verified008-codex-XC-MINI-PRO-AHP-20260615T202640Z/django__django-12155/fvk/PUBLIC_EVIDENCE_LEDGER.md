# Public Evidence Ledger

Status: public intent ledger used by the FVK artifacts.

| ID | Source | Quoted Evidence | Semantic Obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt | "docutils reports an error rendering view docstring when the first line is not empty" | First-line-summary docstrings are in domain and must render without the reported docutils directive error. | Encoded by O2, O3, O4. |
| E2 | prompt | "Currently admindoc works correctly only with docstrings where the first line is empty" | The fix must generalize admindocs beyond the legacy Django-style leading blank line. | Encoded by O2, O4. |
| E3 | prompt | "The culprit is this code in trim_docstring: indent = min(... for line in lines if line.lstrip())" | The indentation calculation in `trim_docstring()` is the defect location to audit. | Encoded by O2. |
| E4 | prompt | "The problem is that the indentation of the first line is 0." | The first line must not participate in the common-margin calculation for later lines. | Encoded by O2. |
| E5 | public hint | "Confirmed the patch fixes the issue, although it crashes for some tests with ValueError: min() arg is an empty sequence." | A skip-first-line implementation must handle the empty tail margin case. | Encoded by O3. |
| E6 | public hint | "We should probably just switch to inspect.cleandoc as it implements the algorithm defined in PEP257." | `inspect.cleandoc()` is public evidence for the intended cleanup algorithm and the safer implementation. | Encoded by O2, O3, O5. |
| E7 | code comment | "Uniformly trim leading/trailing whitespace from docstrings" and "Based on ... PEP-0257" | The helper's intended contract is PEP 257-style docstring cleanup, not an admindocs-specific workaround. | Encoded by O1, O2, O5. |
| E8 | public test | `test_trim_docstring()` expected output for a docstring whose first physical line is empty | Existing leading-empty-line behavior must continue to produce the same cleaned text. | Encoded by O5. |
| E9 | implementation | `parse_rst()` wraps text with `.. default-role:: cmsreference` before and `.. default-role::` after the text. | Retained indentation in the inserted text can become directive content, so dedenting is required before parsing. | Encoded by O4. |
| E10 | implementation | admindocs callsites pass `view_func.__doc__`, `model.__doc__`, and method `__doc__` to `parse_docstring()` or `trim_docstring()` | The helper must remain tolerant of `None` and return a string for all callsites. | Encoded by O1, O6. |

No ledger entry uses hidden tests, benchmark results, internet sources, or the
original upstream fix.
