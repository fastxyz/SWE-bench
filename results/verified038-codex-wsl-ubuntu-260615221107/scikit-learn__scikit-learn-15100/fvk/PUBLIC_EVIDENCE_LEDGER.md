# Public Evidence Ledger

This ledger mirrors the entries in `fvk/SPEC.md`.

- E1: Problem description says `strip_accents="unicode"` fails for strings already in NFKD form. Obligation: already-NFKD inputs are in domain.
- E2: Expected results say `s1` and `s2` should both normalize to `"n"`. Obligation: precomposed and decomposed n-with-tilde return the same stripped value.
- E3: Actual results identify the `normalized == s` no-op as the cause. Obligation: do not preserve the early return as intended behavior.
- E4: Public hint proposes removing the `if` branch. Obligation: unconditional filtering is a public-intent-supported fix.
- E5: Function docstring says accentuated Unicode symbols become simple counterparts. Obligation: remove accent marks for Unicode symbols.
- E6: Vectorizer docs say Unicode mode works on any characters and uses NFKD normalization. Obligation: broad Unicode normalization behavior.
- E7: Public tests cover precomposed Latin and Arabic accent stripping. Obligation: retain existing precomposed behavior.
- E8: Source call path dispatches `strip_accents='unicode'` to this helper. Obligation: preserve signature and dispatch compatibility.

