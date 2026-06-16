# Public Evidence Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E-001 | prompt issue | "`ax.bar` raises an exception in 3.6.1 when passed only nan data." | All-NaN bar coordinate data is in scope; `StopIteration` is a bug, not intended behavior. | Encoded in PO-001 and K claim `ALL_NONFINITE_NO_STOP`. |
| E-002 | prompt reproduction | `ax.bar([np.nan], [np.nan])` | The concrete one-bar all-NaN input must be accepted far enough to create the rectangle/container. | Encoded in PO-002 and K claim `REPRO_SINGLE_NAN`. |
| E-003 | prompt expected outcome | "On 3.6.0 this returns a ... one Rectangle, having `nan` for `x` and `height`." | Nonfinite geometry should be preserved as geometry, not converted into an exception. | Encoded in PO-002. |
| E-004 | prompt debugging | "`ax.bar([np.nan], [0])` raises; `ax.bar([0], [np.nan])` works. So it's about the x position specifically." | The x representative-selection path must handle all-nonfinite x data even when height is finite. | Encoded in PO-001 and PO-002. |
| E-005 | prompt release-note hint | "Fix barplot being empty when first element is NaN" | Mixed leading-NaN data with later finite values should keep using a finite representative. | Encoded in PO-003 and K claim `MIXED_LEADING_NAN_KEEPS_FIRST_FINITE`. |
| E-006 | prompt hint | "it asks for the `next` finite value and does not handle the `StopIteration` exception that you get if there isn't one." | The repair site is the unhandled no-finite-element exception from `_safe_first_finite`. | Encoded in FINDING F-001 and PO-001. |
| E-007 | prompt seaborn context | "I assume you use `np.nan` to avoid triggering any of the autoscaling? Yep, exactly." | The fix should allow phantom NaN bars without changing autoscaling intent. | Encoded as a frame condition in PO-007. |
| E-008 | prompt empty-data note | "`ax.bar([], [])` doesn't return an artist ... so it doesn't work with that pattern." | Empty input behavior is observed context, not a request to create an empty-data artist. | Encoded in PO-004 as unchanged behavior. |
| E-009 | implementation | `_convert_dx` asserts `xconv` is an ndarray and immediately returns `convert(dx)` when `xconv.size == 0`. | Formal domain has an empty-converted-data branch with no representative selection. | Encoded in PO-004 and K claim `EMPTY_XCONV_UNCHANGED`. |
| E-010 | implementation | `_convert_dx` catches `ValueError`, `TypeError`, and `AttributeError` around add/convert/subtract and falls back to `convert(dx)`. | The repair must not disturb existing conversion-error fallback behavior. | Encoded in PO-005. |
| E-011 | implementation | `Axes.bar` calls `_convert_dx` for width and xerr after converting x units. | `_convert_dx` is the causal path from the public `bar` call to the reported traceback. | Encoded in SPEC scope and compatibility audit. |
| E-012 | implementation | `cbook.safe_first_element` delegates to `_safe_first_finite(..., skip_nonfinite=False)`. | The local fallback can select an unfiltered first element without changing global first-finite semantics. | Encoded in PO-001 and PO-002. |
