# FORMAL SPEC ENGLISH

Plain-English paraphrase of the formal claims:

1. If `TK == 0`, `fmi(TK, PK, QK)` returns the zero score.
2. If `TK > 0` and the counts are valid (`TK <= PK` and `TK <= QK` with all
   counts nonnegative), `fmi(TK, PK, QK)` returns the mathematical
   Fowlkes-Mallows score `TK / sqrt(PK * QK)`.
3. The nonzero implementation form is
   `sqrt(TK / PK) * sqrt(TK / QK)`, so the formal execution never evaluates the
   integer product `PK * QK`.
4. The formal proof assumes `TK`, `PK`, and `QK` are already the correct
   contingency-derived counts.
