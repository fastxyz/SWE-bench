# Intent Spec

Intent-only obligations from public evidence:

1. With `text.usetex=True`, datetime tick labels should remain clear and should
   preserve normal date/time spacing.
2. The concrete separator family identified by the public workaround is:
   `- -> {-}`, `: -> {:}`, and literal space -> `\;`.
3. The fix should apply to built-in date formatter strings that Matplotlib wraps
   for TeX.
4. Formatter output with TeX disabled should remain unchanged.
5. The public issue does not require `_wrap_in_tex` to become a general TeX
   escaper or to change public formatter APIs.
6. Existing alphabetic splitting for month/day names may be preserved because it
   does not conflict with the spacing bug and has public compatibility evidence.
