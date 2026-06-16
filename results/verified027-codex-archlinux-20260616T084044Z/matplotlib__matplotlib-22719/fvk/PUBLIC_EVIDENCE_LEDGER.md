# Public Evidence Ledger

Status: constructed, not machine-checked.

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt | `ax.xaxis.update_units(["a", "b"]); ax.plot([], [])` | Empty sequences are in-domain for category-unit conversion after units are established. | Encoded by PO-1 and K claim `CONVERT-EMPTY-VACUOUS-NUMERIC`. |
| E2 | prompt | `MatplotlibDeprecationWarning` is the actual outcome for empty data. | This warning on empty data is a reported bug, not behavior to preserve. | Finding F-001; fixed by V1. |
| E3 | prompt | Expected outcome: "continue producing artists with no data" | Empty conversion should complete with an empty converted result and no deprecation warning. | Encoded by PO-1. |
| E4 | prompt | The traceback also occurs for `ax.convert_xunits([])`. | The fix must be in the unit conversion path, not only in `Axes.plot`. | V1 changes `StrCategoryConverter.convert`; PO-1 covers direct conversion. |
| E5 | public hint | `if values.size and is_numlike` | Numeric pass-through warning should require at least one value. | Implemented in `repo/lib/matplotlib/category.py`. |
| E6 | public hint | `if data.size and convertible` | The all-convertible log should require at least one value. | Implemented in `repo/lib/matplotlib/category.py`. |
| E7 | public tests | `test_convert_one_number`, `test_convert_float_array` expect warnings. | Non-empty numeric pass-through behavior should remain. | Encoded by PO-2. |
| E8 | public tests | `test_convert_fail` and mixed-type plot tests expect `TypeError`. | Non-empty invalid mixed values must still fail validation. | Encoded by PO-4. |
| E9 | public tests/docs | Category docstring and `axis_test` expect ordered string-to-integer mappings. | Non-empty categorical mapping behavior is frame-preserved. | Not changed by V1; tests should be kept. |
| E10 | implementation | `all(...)` over an empty iterator returns true. | Pre-fix branch condition was vacuously true for empty data. | Finding F-001 root cause. |
| E11 | implementation | `convert_xunits` delegates to `Axis.convert_units`, which delegates to the converter. | Converter-level repair covers both plotting and direct unit conversion. | Supports not changing `Axis`/`Artist` APIs. |
