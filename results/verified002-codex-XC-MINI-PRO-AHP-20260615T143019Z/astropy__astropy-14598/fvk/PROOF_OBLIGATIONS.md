# FVK Proof Obligations

Status: constructed, not machine-checked.

## PO1: Formatter Escape And Chunk Preservation

For every in-domain logical Python string `v`, `_format_long_image()` first
computes:

```
e = escape(v)
```

where `escape` doubles every single quote. The chunker then produces an ordered
partition `p_1, ..., p_n` such that:

```
p_1 + ... + p_n == e
```

The exact chunk lengths are not part of the spec; only order and concatenation
are needed for value preservation.

Trace: E4, E7.

## PO2: Full Value/Comment Field Consumption

For each physical long-card value/comment field `vc`, `_split()` must accept
the string parse only when:

```
_strg_comment_RE.fullmatch(vc) succeeds
```

This rejects any parse that recognizes only a prefix and leaves unmatched text,
including the issue family where an escaped quote is followed by a space and a
continuation marker.

Trace: E3, E6, F2.

## PO3: Continuation Marker Removal Without Quote Unescape

For every matched raw escaped payload `r`, `_split()` may:

1. remove padding with `rstrip()`;
2. remove one final `&` if it is the last non-padding character;
3. append the remaining raw escaped payload to the logical value accumulator.

It must not apply `replace("''", "'")` or any other quote unescape at this
stage.

Trace: E2, E5, E7, F1.

## PO4: Synthesized Value/Comment String Is Escaped FITS Text

After all physical value chunks are processed, `_split()` returns a
value/comment field whose string group is:

```
"'" + (p_1 + ... + p_n) + "'"
```

plus the existing comment join. The synthesized field is still FITS-escaped.

Trace: E4, E6, E7.

## PO5: Final Parser Unescapes Exactly Once

For every escaped text `e = escape(v)` in the domain:

```
_parse_value("'" + e + "' / comment").value == unescape(e) == v
```

This is the only unescape step in the audited path.

Trace: E1, E2, F1.

## PO6: Round-Trip Composition

For every in-domain value `v` represented by a long string card:

```
parse_value(split_long(format_long(v))) == observed_value(v)
```

For the issue examples, `observed_value(v) == v`. This covers doubled quotes at
the end of a value and doubled quotes followed by a space and more text.

Trace: E1, E2, E3, F1, F2.

## PO7: Frame And Compatibility

The fix must preserve:

- public method signatures;
- the `Header.fromstring` grouping protocol for `CONTINUE` cards;
- existing long-value comment assembly;
- string formatting behavior outside the `_split()` long-card parser;
- the test suite as fixed, with no test-file edits.

Trace: E4, E8, F3.

## PO8: Honesty Gate

The proof is constructed only. The following commands are the intended later
machine-check path and were not executed:

```sh
kompile fvk/mini-fits-card.k --backend haskell
kast --backend haskell fvk/fits-card-spec.k
kprove fvk/fits-card-spec.k
```

Trace: FVK `verify.md` honesty gate and user constraint forbidding K tooling.
