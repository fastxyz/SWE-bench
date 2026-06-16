# Public Evidence Ledger

Status: constructed for FVK audit, not machine-checked.

| ID | Source | Evidence | Semantic Obligation | Status |
| --- | --- | --- | --- | --- |
| E-001 | prompt | "`django.utils.formats.get_format` should allow lazy parameter" | Lazy string `format_type` values are in-domain inputs for `get_format()`. | Encoded by PO-001 and K claims over `promiseType(S)`. |
| E-002 | prompt | "`some_date|date:_('Y-m-d')`" | The arbitrary custom format string path must work for a lazy translated value. | Encoded by PO-003 and the `rawFormat(S)` claims. |
| E-003 | prompt | "`TypeError: getattr(): attribute name must be string`" | The lazy object must be converted before any string-only `getattr()` lookup. | Encoded by PO-002 and FINDING F-001. |
| E-004 | prompt | "`possibly others are affected too`" | The repair should be in the shared helper, not only the template filter. | Encoded by PO-006 and FINDING F-002. |
| E-005 | code/docstring | "`format_type is the name of the format, e.g. 'DATE_FORMAT'`" | Concrete strings naming registered format settings still use the existing settings/module behavior. | Encoded by PO-004. |
| E-006 | implementation | `get_format()` has cache, localized module lookup, settings fallback, and arbitrary string fallback branches. | The proof must cover each branch for a lazy string. | Encoded by PO-001 through PO-004. |
| E-007 | baseline notes | "Coercing all `format_type` values with `str()` was rejected" | The fix should not expand support to unrelated non-string objects. | Encoded by PO-005. |
