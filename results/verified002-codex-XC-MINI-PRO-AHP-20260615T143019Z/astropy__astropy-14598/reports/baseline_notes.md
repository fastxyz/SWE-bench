# Baseline Notes

## Root Cause

Long FITS string cards are reconstructed in `Card._split()` by iterating over
the physical `CONTINUE` cards and synthesizing a single value/comment field for
the normal value parser. That reconstruction was unescaping doubled single
quotes in each physical piece with `replace("''", "'")`, then wrapping the
joined result in quotes. The normal value parser later unescaped doubled quotes
again, so logical values that genuinely contained adjacent single quotes could
lose one quote after a round trip through `Card.fromstring(str(card))`.

The same path used a prefix regex match for the value/comment field. When a
doubled quote was followed by a space and then the continuation ampersand, the
regex could accept the quote before the space as the closing FITS quote and
ignore the remaining `&'` suffix. That caused the continuation marker handling
to miss the remaining continued text.

## Changed Files

`repo/astropy/io/fits/card.py`

- Changed the long-card value/comment parse from `match()` to `fullmatch()` so
  a `CONTINUE` card's full value/comment field must be consumed before it is
  accepted.
- Stopped unescaping doubled single quotes while collecting continued string
  pieces. The reconstructed value/comment field now remains FITS-escaped until
  `_parse_value()` performs the existing single unescape step.

`reports/baseline_notes.md`

- Added this report describing the root cause, the source change, and the
  assumptions considered.

## Assumptions and Alternatives

I assumed the intended invariant is that `_split()` should return a syntactically
valid FITS value/comment string for non-commentary cards, leaving final type
conversion and quote unescaping to `_parse_value()`. That matches the existing
non-continued card path.

I considered changing the FITS string regular expression itself, but that regex
is shared with the broader card parser and has compatibility-sensitive behavior
around non-standard cards. Using `fullmatch()` only in the `CONTINUE`
reassembly path is narrower and directly addresses the prefix-match failure.

I also considered unescaping the joined continued value and then re-escaping it
before returning from `_split()`. That would be more work for the same result
and would still rely on correctly handling every boundary case twice. Preserving
the existing escaped representation until the normal parser runs is simpler and
keeps quote handling in one place.
