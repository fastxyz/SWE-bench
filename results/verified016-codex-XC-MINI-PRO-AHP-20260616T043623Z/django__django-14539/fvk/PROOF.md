# PROOF: django__django-14539

Status: constructed, not machine-checked. No tests, Python snippets, `kompile`,
`kast`, or `kprove` were run.

## Claim

The V2 `trim_punctuation()` implementation satisfies the source-span trimming
contract in `fvk/SPEC.md` for the audited URL punctuation cases:

1. literal trailing punctuation after escaped URL text;
2. valid or entity-like non-punctuation HTML entities followed by punctuation;
3. trailing punctuation represented by an HTML entity;
4. existing literal punctuation runs.

## Proof Sketch

Let `U = html.unescape(middle)` and `stripped = U.rstrip(TRAILING_PUNCTUATION_CHARS)`.
The branch is entered only when `U != stripped`. Therefore
`punctuation_count = len(U) - len(stripped)` is positive.

### Entity path

The loop first checks the source suffix starting at the last `&`. If that suffix
unescapes to a non-empty string made only of trailing punctuation characters,
the whole source suffix is prepended to `trail` and removed from `middle`.

This discharges O-005: for `google.com/&#33;`, the checked suffix `&#33;`
unescapes to `!`, so V2 moves `&#33;` as a whole. V1 moved only `;`, breaking
the entity. Because the moved suffix is removed from the end of `middle` and
prepended to `trail`, O-002 also holds for this step.

The loop decreases `punctuation_count` by `len(escaped)`, which is positive by
the guard. This discharges the entity-path part of O-008.

### Literal path

If the checked suffix is not an entity whose entire unescaped value is trailing
punctuation, V2 moves a suffix of literal trailing punctuation characters. It
uses:

```text
min(punctuation_count, len(middle) - len(middle.rstrip(TRAILING_PUNCTUATION_CHARS)))
```

with a fallback of `1` only for progress in degenerate source/unescape cases.
For the reported input `google.com/?q=1&lt!`, the last-`&` suffix is `&lt!`,
which unescapes to `<!`; because `<` is not trailing punctuation, the entity
path is skipped. The literal path moves only `!`, leaving
`google.com/?q=1&lt` in `middle`. This discharges O-001, O-002, O-003, and O-004
for the issue example.

The same reasoning covers `&lt;!` and `&amp;!`: the whole suffix does not
unescape entirely to trailing punctuation, so only the literal `!` moves.

For ordinary punctuation runs such as `example!!`, the literal run length is
`2`, so both `!` characters move together. This preserves O-007.

The literal path decreases `punctuation_count` by at least `1`, discharging the
literal-path part of O-008.

### Composition with `urlize()`

After `trim_punctuation()` returns, V2 leaves all existing downstream behavior
unchanged. `urlize()` still computes the href with
`smart_urlquote(html.unescape(middle))`, uses the corrected source `middle` as
the display text, and then concatenates `lead + link + trail`.

For the reported example, the corrected `middle` is `google.com/?q=1&lt`; its
unescaped URL is `google.com/?q=1<`, which is quoted into
`http://google.com/?q=1%3C`. The corrected `trail` is exactly `!`. Therefore the
expected prompt output follows.

## Residual Risk

The proof is over a mini source-span model, not full Python or full Django
template rendering. It is partial correctness only. Termination of the added
inner loop is argued by a decreasing integer measure, but no K tool was run.

Test redundancy: no test removal is recommended in this benchmark. Existing and
future tests should be kept until the emitted K commands and the Django test
suite are run in an environment where execution is allowed.
