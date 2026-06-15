# Formal Spec English

Status: constructed for FVK audit; not machine-checked.

The K claims in `fits-card-format-spec.k` say the following:

1. `(SHORT-REP-PREFERENCE)`: for any float view whose normalized
   `str(value)` token has length at most 20, `formatFloat` returns the
   normalized/capped version of that `str(value)` token, not the legacy `.16G`
   token.
2. `(LEGACY-FALLBACK)`: for any float view whose normalized `str(value)` token
   is longer than 20 characters, `formatFloat` returns the normalized/capped
   version of the legacy `.16G` token.
3. `(REPORTED-FLOAT)`: for the concrete float view with short token
   `0.009125` and legacy token `0.009124999999999999`, `formatFloat` returns
   exactly `0.009125`.
4. `(REPORTED-HIERARCH-CARD)`: the reported HIERARCH radius card formats to the
   full 80-character card image with value token `0.009125` and the complete
   comment.
5. `(EXPONENT-NORMALIZATION)`: a lowercase exponent marker in the selected
   short representation is normalized to uppercase before output.
6. `(PARSED-VALUESTRING-FRAME)`: an unmodified parsed value string remains a
   frame condition of `Card._format_value()` and is not changed by this helper
   patch.

There are no loop circularities: the audited helper path is straight-line
selection and normalization logic.
