# Public Compatibility Audit

Changed public symbols:

- `sqf_part()` docstring only.
- `sqf_list()` behavior and docstring.
- `sqf()` docstring only.

Changed helper symbols:

- Added `_combine_factors()`.
- Added `_sqf_list_should_combine()`.
- Changed `_generic_factor_list()` for `method == 'sqf'` only.

Compatibility checks:

| Surface | Status | Notes |
| --- | --- | --- |
| `factor_list()` | Preserved | `_generic_factor_list()` calls `_combine_factors()` only when `method == 'sqf'`. |
| `sqf_list(..., polys=True)` | Preserved shape | Combination happens while entries are `Poly`; the existing `polys` conversion branch still decides output type. |
| `sqf_list(..., frac=True)` | Preserved shape | Numerator and denominator lists are grouped independently, then returned in the existing `(coeff, fp, fq)` shape. |
| `sqf_list(1)` | Preserved | Empty factor lists remain unchanged because `_combine_factors([]) == []` and the gate is false without a generator. |
| No-generator multivariate `sqf_list()` | Preserved | The gate requires explicit single-generator input or no ambiguity. This is a compatibility frame, not a proof of ideal behavior. |
| Public tests | Not modified | The task forbids test edits. Existing public multivariate behavior remains framed as ambiguous. |
