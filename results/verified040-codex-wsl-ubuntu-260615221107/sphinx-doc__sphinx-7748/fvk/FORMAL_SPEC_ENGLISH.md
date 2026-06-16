# Formal Spec in English

1. `FIND-TWO`: If the first docstring starts with two valid signature lines for
   the documented object followed by body text, `find` returns both signature
   pairs in order and the remaining docstring starts at the body text.
2. `FIND-THREE-PREFIX`: The same property holds for three leading signatures,
   demonstrating the family behavior is not limited to two.
3. `FIND-STOPS-AT-PROSE`: If prose appears after the first leading signature,
   collection stops and later signature-looking lines remain in the remainder.
4. `FIND-NO-MATCH`: If the first line is not a valid signature for the
   documented object, no signature is extracted from that docstring.
5. `FIND-SINGLE-COMPAT`: The first-signature projection returns the only pair
   for a one-signature docstring.
6. `FORMAT-SINGLE`: Formatting one pair produces one signature string.
7. `FORMAT-TWO`: Formatting two pairs produces two signature strings separated
   by exactly one newline in the original order.
8. `STRIP-WRAPPER-NO-REEMIT`: After the first-signature wrapper strips leading
   signatures, a second plural lookup over the stripped body finds no signature
   to emit for strip-only documenters.
9. `FORMAT-EXPLICIT-BYPASS`: If an explicit signature exists, the docstring
   extraction path is not used.
