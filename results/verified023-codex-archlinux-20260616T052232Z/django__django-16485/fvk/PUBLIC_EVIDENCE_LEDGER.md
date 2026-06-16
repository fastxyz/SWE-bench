# Public Evidence Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E-01 | `benchmark/PROBLEM.md` | `floatformat() crashes on "0.00"` | A zero-valued decimal string with explicit fractional scale is in-domain and must not crash. | Encoded in C-01 and C-02. |
| E-02 | `benchmark/PROBLEM.md` | `floatformat('0.00', 0)` and `floatformat(Decimal('0.00'), 0)` | Both string and Decimal zero values with `arg=0` must be handled by the same numeric formatting path. | Encoded in C-02. |
| E-03 | `repo/docs/ref/templates/builtins.txt` | Passing zero as the argument rounds to the nearest integer. | `arg=0` is public API; zero input should format as integer string `"0"`. | Encoded in C-02. |
| E-04 | `repo/docs/ref/templates/builtins.txt` | Positive integer arguments fix the number of decimal places; negative arguments omit decimal places when no decimal part is displayed. | Positive and negative precision behavior are frame conditions. | C-01 covers non-crash for positive precision; C-03 covers negative zero branch. |
| E-05 | `repo/docs/ref/templates/builtins.txt` | `g` and `u` suffixes control grouping and localization. | The patch must not change public suffix parsing or public signature. | Compatibility audit passes; not modeled in mini semantics. |
| E-06 | `benchmark/PROBLEM.md` | `ValueError: valid range for prec is [1, MAX_PREC]` | A constructed Decimal context precision must be at least `1`. | Encoded in C-01 and PO-02. |
| E-07 | `repo/tests/template_tests/filter_tests/test_floatformat.py` | Existing assertions cover invalid non-empty arguments and negative rounded zero. | Do not regress established invalid-argument and rounded-zero behavior. | Frame condition PO-04; no test edits. |
