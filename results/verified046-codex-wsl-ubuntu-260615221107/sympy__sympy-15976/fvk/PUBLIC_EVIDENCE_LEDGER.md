# Public Evidence Ledger

| ID | Source | Evidence | Obligation | Status |
|---|---|---|---|---|
| I1 | Issue title | "A symbol ending with a number is made invisible when printing with MathML" | Avoid emitted presentation structure that hides `x2` in Safari. | Encoded |
| I2 | Issue hint | `<mi><msub><mi>r</mi><mi>2</mi></msub></mi>` has extra `mi`; corrected shape is `<msub>...` | Top-level subscripted presentation symbol is `msub`, not `mi`. | Encoded |
| I3 | Issue HTML | `x2*z + x2**3` contains two old `mi(msub(...))` occurrences | Fix must compose through product and power contexts. | Encoded |
| I4 | Source comment | trailing digits are treated as subscripts | Preserve subscript interpretation of `x2`. | Encoded |
| I5 | Public tests | scripted presentation symbol tests assert top-level `mi` | SUSPECT legacy behavior because it conflicts with I2. | Finding |
| I6 | Public tests/API | plain matrix symbol bold output uses `mathvariant="bold"` on `mi` | Preserve plain-symbol and bold setting behavior. | Encoded |
