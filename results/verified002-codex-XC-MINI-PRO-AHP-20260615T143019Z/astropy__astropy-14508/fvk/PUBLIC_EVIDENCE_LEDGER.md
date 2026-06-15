# Public Evidence Ledger

Status: constructed for FVK audit; not machine-checked.

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | "`io.fits.Card` may use a string representation of floats that is larger than necessary" | New float serialization must avoid unnecessarily long binary-approximation text. | Encoded in PO1 and PO4. |
| E2 | `benchmark/PROBLEM.md` | "Being able to create any valid FITS Card via `io.fits.Card`." | If keyword/value/comment fit in a valid FITS card image, Card construction should not force truncation by over-expanding the value. | Encoded in PO4. |
| E3 | `benchmark/PROBLEM.md` | `HIERARCH ESO IFM CL RADIUS = 0.009125 / [m] radius arround actuator to avoid` | The reported HIERARCH card is an in-domain concrete case. | Encoded in PO4. |
| E4 | `benchmark/PROBLEM.md` | "the value `0.009125` is being unnecessarily expanded to `0.009124999999999999`" | Expected float token for this value is `0.009125`; legacy token is suspect behavior. | Encoded in PO1 and F1. |
| E5 | `benchmark/PROBLEM.md` | "before doing `f\"{value:.16G}\"`, we should attempt to use ... `str(value)`, and ... only attempt to format it ourselves if the resulting string does not fit in 20 characters" | Selection order is `str(value)` first, `.16G` fallback only for over-20-character strings. | Encoded in PO1 and PO3. |
| E6 | Public hint in `benchmark/PROBLEM.md` | "python floats by default now have reprs that use the right number of digits to be reproducible" | `str(value)` is an intent-derived default for new float token generation. | Encoded in PO1. |
| E7 | `repo/astropy/io/fits/card.py` comments and verifier regex | Existing code normalizes exponent text and validates standard numeric values with uppercase exponent markers. | Preserve uppercase exponent normalization and decimal-point handling. | Encoded in PO2. |
| E8 | `repo/astropy/io/fits/card.py` | `_format_float()` limits the value string to at most 20 characters. | Preserve the helper's 20-character cap. | Encoded in PO3. |
| E9 | `repo/astropy/io/fits/card.py` | `_format_value()` preserves `_valuestring` when the value was parsed and not modified. | Do not route unmodified parsed float cards through the new formatting path. | Encoded in PO5. |
| E10 | Source compatibility audit | `_format_float` is a private helper; public `Card` APIs were not re-signed. | No public API compatibility changes. | Encoded in PO6. |
