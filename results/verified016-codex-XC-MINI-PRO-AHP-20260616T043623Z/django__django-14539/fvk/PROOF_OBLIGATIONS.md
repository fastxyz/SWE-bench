# PROOF OBLIGATIONS: django__django-14539

Status: constructed, not machine-checked.

## O-001: Reported example obligation

For input word `google.com/?q=1&lt!`, `trim_punctuation()` must split:

- kept source middle: `google.com/?q=1&lt`
- moved trail source: `!`

Then `urlize()` builds href `http://google.com/?q=1%3C` from
`html.unescape("google.com/?q=1&lt")`, while preserving the display source
`google.com/?q=1&lt`.

Traces to findings: F-001.

## O-002: Source partition, no duplication

For every trim step, the original source suffix moved to `trail` and the
remaining `middle` must form a partition of the previous `middle`:

```text
middle_before == middle_after + moved_source_suffix
trail_after == moved_source_suffix + trail_before
```

No character may appear in both `middle_after` and `trail_after`.

Traces to findings: F-001, F-002.

## O-003: Unescaped trailing punctuation contract

Let `U = html.unescape(middle_before)` and let `S` be `U` after removing the
maximal trailing suffix of characters in `TRAILING_PUNCTUATION_CHARS`.
After trimming:

```text
html.unescape(middle_after) == S
```

Traces to findings: F-001, F-002.

## O-004: Non-punctuation entities are preserved inside the link

If the trailing source suffix contains an entity or entity-like sequence whose
unescaped value is not entirely trailing punctuation, that source span must not
be moved merely because it is longer than its unescaped text.

Required examples:

- `&lt!` keeps `&lt` and moves `!`.
- `&lt;!` keeps `&lt;` and moves `!`.
- `&amp;!` keeps `&amp;` and moves `!`.

Traces to findings: F-001, F-003.

## O-005: Entity-encoded punctuation moves as a whole source span

If the trailing source suffix begins at an `&`, `html.unescape(suffix)` is
non-empty, and every unescaped character of that suffix is in
`TRAILING_PUNCTUATION_CHARS`, the whole source suffix must move to `trail`.

Required examples:

- `google.com/&#33;` keeps `google.com/` and moves `&#33;`.
- `google.com/&semi;` keeps `google.com/` and moves `&semi;`.
- `google.com/&semi;!` keeps `google.com/` and moves `&semi;!`.

Traces to findings: F-002.

## O-006: Frame condition for href and display text

Once `middle_after` is computed, existing URL handling remains unchanged:

- href generation still uses `smart_urlquote(html.unescape(middle_after))`.
- display text still uses `middle_after`, subject to the existing `trim_url()`
  and `autoescape` branches.
- `lead`, `nofollow`, email handling, IDN handling, and URL regex matching are
  not changed.

Traces to findings: F-003.

## O-007: Literal punctuation runs remain grouped

For source suffixes that are literal punctuation characters, V2 must move the
maximal needed literal run in one step. This preserves the existing public
behavior for inputs such as:

- `http://testing.com/example!!`
- `http://testing.com/example.,:;)\"!`
- the query-string case containing `dj!` followed by a backtick, `?`, and
  trailing `!` from the public urlize tests.

Traces to findings: F-003.

## O-008: Progress and bounded local loop

The inner `while punctuation_count:` loop must strictly decrease
`punctuation_count` on every iteration:

- entity path decreases it by `len(escaped)`, which is positive because
  `escaped` is required to be non-empty;
- literal path decreases it by `punctuation`, which is at least `1`.

This establishes partial-correctness progress for the new loop. Full runtime
performance is not machine-proved, but unchanged/no-trailing cases do not enter
the loop, and literal punctuation runs are trimmed by run length rather than one
character at a time.

Traces to findings: F-004.

## O-009: Honesty gate

The proof artifacts and commands must be emitted, but not executed in this
benchmark. Claims remain constructed, not machine-checked, until `kprove`
returns `#Top` in a permitted environment.

Traces to findings: F-004.

## Machine-check commands, not executed

```sh
kompile fvk/mini-urlize.k --backend haskell
kast --backend haskell fvk/urlize-trim-spec.k
kprove fvk/urlize-trim-spec.k --definition fvk/mini-urlize-kompiled
```
