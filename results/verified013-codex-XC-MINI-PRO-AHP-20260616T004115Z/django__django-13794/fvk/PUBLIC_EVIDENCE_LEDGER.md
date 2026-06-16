# Public Evidence Ledger

Status: constructed for FVK audit; not machine-checked.

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E-1 | `benchmark/PROBLEM.md` | "`add` filter is unable to concatenate strings with lazy string" | A normal string plus a lazy string is in-domain for `add` and must not produce `""` merely because the lazy value is a proxy. | Encoded by PO-2, PO-4, and K claims `ADD-LAZY-RIGHT-PLUS` / `ADD-LAZY-LEFT-PLUS`. |
| E-2 | `benchmark/PROBLEM.md` | "TypeError: can only concatenate str (not `\"__proxy__\"`) to str" | The defect mechanism is the fallback `value + arg` seeing a proxy instead of text. | Encoded by resolving text promises before integer/addition branches. |
| E-3 | `repo/docs/ref/templates/builtins.txt:1261` | "first try to coerce both values to integers" | Integer coercion has priority over string concatenation. | Encoded by PO-3 and K claim `ADD-INT`. |
| E-4 | `repo/docs/ref/templates/builtins.txt:1261-1264` | "If this fails, it'll attempt to add the values together anyway... If it fails, the result will be an empty string." | Native `+` is second priority; empty string is the final failure fallback. | Encoded by PO-4, PO-5, K claims `ADD-PLUS` and `ADD-EMPTY`. |
| E-5 | `repo/docs/ref/templates/builtins.txt:1273-1276` | "Strings that can be coerced to integers will be summed, not concatenated" | Numeric lazy strings must be summed after being resolved to text. | Encoded by PO-3 and K claim `ADD-LAZY-RIGHT-INT`. |
| E-6 | `repo/django/utils/functional.py:68-73` | `Promise` is the base class used to recognize lazy proxy values. | The filter may identify lazy values by `isinstance(..., Promise)`. | Encoded by PO-2 and source line `defaultfilters.py:678`. |
| E-7 | `repo/django/utils/functional.py:120-125` and `repo/django/utils/translation/__init__.py:135-136` | Lazy text proxies set `_delegate_text` when `str` is in result classes; `gettext_lazy = lazy(gettext, str)`. | The reported lazy translation string is a text promise and can be resolved with `str()`. | Encoded by PO-2. |
| E-8 | `repo/tests/template_tests/filter_tests/test_add.py` and docs examples | Existing public tests cover integer addition, incompatible operands, list/tuple/date-style fallback. | V1 must preserve non-lazy behavior. | Encoded by PO-6 and compatibility audit. |

