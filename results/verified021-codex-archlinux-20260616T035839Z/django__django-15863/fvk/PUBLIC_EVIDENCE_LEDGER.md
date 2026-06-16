# Public Evidence Ledger

Status: public evidence only.

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E-1 | `benchmark/PROBLEM.md` | "Filter floatformat drops precision in decimal numbers" | Decimal precision is the defect axis. | Encoded by PO-1, PO-2. |
| E-2 | `benchmark/PROBLEM.md` | `Decimal('42.12345678901234567890')` rendered with `floatformat:20` currently prints `42.12345678901234400000` | The issue example must render from the exact Decimal value, producing `42.12345678901234567890`. | Encoded by PO-3 and claim `ISSUE-DECIMAL-20`. |
| E-3 | `benchmark/PROBLEM.md` | "Decimal numbers are converted to float instead." | The implementation must not route existing Decimal objects through `float(text)`. | Encoded by PO-2 and claim `DECIMAL-PRESERVE`. |
| E-4 | `repo/docs/ref/templates/builtins.txt` | "`floatformat` rounds a number to that many decimal places" | The output is numeric rounding/formatting, not Python object representation, for in-domain numeric values. | Encoded by PO-1, PO-3. |
| E-5 | `repo/docs/ref/templates/builtins.txt` | `g` suffix forces grouping; `u` suffix disables localization; no argument is equivalent to `-1` | Suffix and localization behavior must be framed unchanged by the fix. | Encoded by PO-4. |
| E-6 | `repo/tests/template_tests/filter_tests/test_floatformat.py` | Decimal examples `Decimal("555.555") -> "555.56"` and `Decimal("09.000") -> "9"` | Decimal inputs are already public in-domain values for this filter. | Encoded by PO-1. |
| E-7 | `repo/tests/template_tests/filter_tests/test_floatformat.py` | Existing float, string, grouping, invalid suffix, infinity, and low-context Decimal tests | Non-Decimal and suffix behavior must not be changed to fix Decimal precision. | Encoded by PO-4 and finding F-003. |
| E-8 | `repo/django/template/defaultfilters.py` | The implementation uses `Decimal.quantize(..., ROUND_HALF_UP, Context(prec=prec))` after conversion | Once the exact Decimal reaches the rounding path, existing rounding machinery is the intended contributor to preserve. | Encoded by PO-3; treated as implementation evidence, not standalone intent. |
