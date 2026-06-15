# FVK Spec: FITS Card Long-String Quote Preservation

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Scope

This FVK pass audits the V1 production change in
`repo/astropy/io/fits/card.py`, specifically the long-card path in
`Card._split()` and its composition with `_format_long_image()` and
`_parse_value()`.

The audited observable is:

```
fits.Card.fromstring(str(fits.Card(keyword, value, comment))).value
```

for printable-ASCII string `value` values that are represented with the FITS
`CONTINUE` convention. The proof is partial correctness over the parser and
formatter path: if the card image is produced or accepted as a syntactically
valid `CONTINUE` string card, parsing preserves the logical string value.

## Intent-Only Specification

1. FITS `Card` string values must round trip through the card image without
   losing doubled single quotes.
2. The `CONTINUE` ampersand is a representation marker, not part of the logical
   string value.
3. `CONTINUE` cards should be transparent to callers: a set of physical cards is
   accessed as one logical card value.
4. FITS single-quote escaping is represented by doubled quote characters in the
   serialized value and should be decoded exactly once when producing the Python
   string value.
5. Comments and public APIs are frame conditions for this fix: no public
   signature, return type, or header/card producer-consumer protocol should
   change.

## Public Evidence Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | `Card.fromstring(str(card1))  # Should be the same as card1` | The round-trip value of a serialized card must equal the original logical value. | Encoded by PO6. |
| E2 | `benchmark/PROBLEM.md` | Values ending in `''` sometimes become values ending in `'`. | A doubled quote in the logical Python value must not be collapsed by long-card parsing. | Encoded by PO3, PO5, PO6. |
| E3 | `benchmark/PROBLEM.md` | `"x"*100 + "'' aaa"` loses the string after the quotes when a space is between. | A parser must not accept a prefix string match that leaves a continuation suffix unconsumed. | Encoded by PO2. |
| E4 | `repo/docs/io/fits/usage/headers.rst` | `CONTINUE` cards are automatic for long string values. | Long values are in-domain; `CONTINUE` is an implementation representation, not a caller-visible value split. | Encoded by PO1, PO4, PO6. |
| E5 | `repo/docs/io/fits/usage/headers.rst` | The ampersand at the end of each 80-character card image is not part of the string value. | The long-card parser removes only the continuation marker. | Encoded by PO3. |
| E6 | `repo/astropy/io/fits/card.py` comments | `_strg_comment_RE` is "Used in cards using the CONTINUE convention which expect a string followed by an optional comment". | The long-card value/comment field must parse as one string plus optional comment. | Encoded by PO2 and PO4. |
| E7 | `repo/astropy/io/fits/card.py` implementation | `_format_long_image()` escapes `'` as `''` before splitting into physical cards. | The parser's raw reassembly domain is escaped chunk text; unescaping belongs after reassembly. | Encoded by PO1, PO3, PO5. |
| E8 | Public tests in `repo/astropy/io/fits/tests/test_header.py` | Existing long-string tests expect `CONTINUE` representation and transparent value/comment access. | Existing `CONTINUE` representation and comment handling are frame conditions. | Encoded by PO7. |

The pre-fix outputs shown in the issue are SUSPECT legacy behavior under FVK:
they exhibit the bug and are not accepted as expected results.

## Abstract Model

The proof uses an algebraic abstraction of the changed path. It keeps the
observable axes that matter for the bug: escaped quote multiplicity, chunk
order, full-string parsing versus prefix parsing, continuation-marker removal,
and the single final unescape.

Definitions:

- `escape(v)`: replace every logical single quote in `v` with doubled single
  quotes.
- `unescape(e)`: replace every doubled single quote in escaped text `e` with
  one logical quote.
- `chunks(e)`: any non-empty ordered partition of escaped text `e` produced by
  the existing long-string chunker. The proof does not rely on exact chunk
  lengths, only that concatenating the chunks recovers `e`.
- `field(p, cont)`: the physical value field for raw escaped payload `p`, with
  a trailing `&` marker iff `cont` is true.
- `parse_full(field)`: accepts only if the whole field is consumed as a quoted
  FITS string plus optional comment.
- `strip_continue(raw)`: trims padding and removes a final `&` marker if one is
  present.
- `split_long(image)`: iterates physical cards, parses each field with
  `parse_full`, appends `strip_continue(raw_payload)` without unescaping, and
  returns a synthesized escaped FITS value/comment string.
- `parse_value(valuecomment)`: parses the synthesized value/comment string and
  applies `unescape` exactly once to the string group.

## Formal Contract

For every printable-ASCII string `v`, keyword `k`, optional comment `c`, and
valid long-string image `img = format_long(k, v, c)`:

```
parse_value(split_long(img)) == observed_value(v)
```

where `observed_value(v)` is the value exposed by `Card.value` under the
existing header whitespace policy. For the issue examples, no trailing
whitespace is involved, so `observed_value(v) == v`.

The frame condition is:

```
parse_comment(split_long(format_long(k, v, c))) == existing_comment_join(c)
```

and no public method signature, keyword handling, header scanning behavior, or
test file is changed.

## Out Of Scope

- General validation of malformed FITS strings with odd or otherwise invalid
  quote counts. The existing parser already documents leniency in this area.
- Termination and performance of the complete Astropy FITS stack.
- Full machine-checked proof against real Python semantics. The artifacts use a
  focused mini semantics and are constructed only.
