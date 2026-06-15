# Baseline Notes

## Root cause

The CDS unit parser uses a right-recursive grammar for `combined_units`. For a
chain such as `J/m/s/kpc2`, the parse tree is effectively `J / (m / (s / kpc2))`
instead of treating each slash-separated unit after the numerator as another
denominator factor. That moves later denominator units back into the numerator,
which is why `10+3J/m/s/kpc2` was parsed as `1000 J s / (kpc2 m)` and
`10-7J/s/kpc2` as `1e-07 J kpc2 / s`.

## Changed files

`repo/astropy/units/format/cds.py`

Added a small internal `_CDSUnit` semantic value used by the existing parser
actions. It stores both the actual unit value for the parsed expression and a
flattened `division_tail` value for expressions that appear to the right of a
slash. The division action now divides by that flattened tail, so chained CDS
division such as `J/m/s/kpc2` keeps `m`, `s`, and `kpc2` in the denominator.
Parenthesized expressions are wrapped with their actual unit as the tail, so
explicit grouping such as `J/(m/s)` still preserves the grouping.

## Assumptions and alternatives

I assumed the intended CDS interpretation for repeated slash-separated units is
the same as the issue examples and Astropy's generic parser behavior: later
slash terms continue the denominator unless parentheses explicitly group them.

I considered changing the PLY grammar to a left-recursive division production,
but that would require regenerating and updating the shipped parser table. The
smaller semantic-action change fixes the root cause while preserving the
existing production signatures used by `cds_parsetab.py`.

I did not run tests or execute parser examples because the task explicitly says
this benchmark session has no execution environment and no code should be run.
