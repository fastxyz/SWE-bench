# FVK Notes

The FVK audit keeps V1 unchanged. The central resolved issue is F-001: a normal
string plus a Django text lazy proxy previously reached the filter's
empty-string fallback. PO-2 requires resolving `_delegate_text` promises before
branch selection, and PO-4 proves that the existing native-addition fallback then
receives two strings and returns their concatenation.

I also kept the V1 placement inside `django.template.defaultfilters.add()`
rather than changing `django.utils.functional.lazy()`. F-004 rejects the global
proxy alternative because it has a broader compatibility surface, while PO-7
shows the public filter API and registration are unchanged.

No additional source edit was made after V1. F-002 and PO-3 confirm that
numeric lazy strings still follow the documented integer-sum precedence. F-003
and PO-6 confirm non-lazy and non-text-lazy operands continue through the
original `int()` / `+` / `""` branch order. F-005 records the honesty caveat:
the proof is constructed only, and no tests, Python, or K commands were run.

