# Public Evidence Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | "`translate_url()` creates an incorrect URL when optional named groups are missing in the URL pattern" | Translating a resolved URL with an absent optional named capture must produce the translated URL with that component omitted, not an incorrect component. | Encoded by PO-1 and PO-3. |
| E2 | `benchmark/PROBLEM.md` public hint | "`resolve()` will return None for any optional capture groups that aren't captured, but `reverse()` ... convert it to the literal string 'None'." | `None` from uncaptured optional groups is a missing argument for reverse construction. | Encoded by PO-1, PO-2, PO-3. |
| E3 | `benchmark/PROBLEM.md` public hint | "solve it within `reverse()`. We would discard any arguments that are `None`." | The shared reverse implementation must discard `None` values before candidate matching and substitution. | Encoded by PO-1 through PO-4. |
| E4 | `benchmark/PROBLEM.md` public hint | "`{% url 'my_view' obj.might_be_none %}`" as the cleaner syntax | Positional `None` must also be treated as omitted, not only keyword `None`. | Encoded by PO-2. |
| E5 | `benchmark/PROBLEM.md` public hint | "Non-existent template variables will still pass an empty string rather than None, so this won't hide any typos" | Empty strings and other non-`None` values must be preserved. | Encoded by PO-4. |
| E6 | `repo/django/urls/base.py` | `translate_url()` calls `reverse(..., args=match.args, kwargs=match.kwargs)` | Fixing `_reverse_with_prefix()` covers `translate_url()` because resolved kwargs flow directly into reverse. | Compatibility and scope evidence. |
| E7 | `repo/django/template/defaulttags.py` | `URLNode.render()` resolves template args/kwargs and calls `reverse()` | Fixing `_reverse_with_prefix()` covers `{% url %}` without changing template code. | Compatibility and scope evidence. |
| E8 | `repo/tests/urlpatterns_reverse/tests.py` public fixture | Existing optional reverse cases expect `/optional/1/` when only `arg1` is supplied and `/optional/1/2/` when `arg2` is supplied. | Candidate selection must keep the existing omitted-vs-present optional component distinction. | Supporting evidence for PO-3. |

