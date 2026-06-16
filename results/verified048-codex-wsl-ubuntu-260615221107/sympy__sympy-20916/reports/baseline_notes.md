# Baseline Notes

## Root cause

`sympy.printing.conventions.split_super_sub` has a special case that treats
trailing digits in a symbol name as an implicit subscript. That special case
used `_name_with_digits_p = re.compile(r'^([a-zA-Z]+)([0-9]+)$')`, so it only
recognized ASCII Latin letters before the digit run. A symbol named `w0` was
split into `("w", [], ["0"])`, but a symbol named `ω0` was left as one name
with no subscript. The unicode pretty printer then had no subscript component
to convert to `₀`.

## Files changed

`repo/sympy/printing/conventions.py`

Changed `_name_with_digits_p` to match a leading run of Unicode word
characters excluding digits and underscore, followed by ASCII digits. This
keeps the existing implicit-subscript rule limited to letter-like names ending
in ordinary digits while allowing non-ASCII letters such as Greek `ω`.

## Assumptions and alternatives

I assumed the intended behavior is that Unicode letters should participate in
the same implicit trailing-digit subscript rule as ASCII letters, without
changing the handling of names that use explicit underscores or carets.

The public hint suggested replacing `[a-zA-Z]` with `\w`. I rejected a direct
greedy `(\w+)([0-9]+)` replacement because `\w` also includes digits, which
would split a multi-digit name like `x10` as base `x1` and subscript `0`.
Using a non-greedy `\w+?` would preserve `x10`, but it would also broaden the
rule to bases containing digits or underscores. The chosen pattern is narrower:
it adds Unicode letter support while preserving the old "letters followed by
digits" shape.

I did not modify tests, and I did not run tests or project code because the
task instructions forbid both in this benchmark session.
