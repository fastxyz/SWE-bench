# Formal Spec English

These are English paraphrases of the K claims in `polyval-spec.k`.

C1. For a list of raw `timedelta64` coordinate values, `ensureNumeric` maps each
`td(T)` value to numeric `n(T)`, where `T` is the duration in nanoseconds from
zero. It does not use a datetime epoch offset.

C2. For a list of raw `datetime64` coordinate values, `ensureNumeric` maps each
`dt(T)` value to numeric `n(T)`, where `T` is already modeled as nanoseconds
since 1970-01-01. This preserves the existing epoch-nanosecond convention.

C3. For numeric coordinate values, `ensureNumeric` maps each `num(N)` value to
`n(N)`, preserving non-datetime-like inputs.

C4. For missing datetime-like values modeled as `nat`, `ensureNumeric` maps the
value to `nan`.

C5. `polyval` first applies `ensureNumeric` to the coordinate values, then
evaluates every numericized coordinate with Horner's method using the coefficient
map and maximum degree.

C6. The proof scope is partial correctness of this conversion/evaluation slice.
It does not prove termination or all behavior of xarray's full `DataArray` and
`Dataset` machinery.
