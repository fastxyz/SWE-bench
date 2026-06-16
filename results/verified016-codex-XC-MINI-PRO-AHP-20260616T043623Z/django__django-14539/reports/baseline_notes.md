# Baseline Notes

## Root cause

`django.utils.html.urlize()` trims trailing punctuation from a candidate URL in
`trim_punctuation()`. To avoid treating the semicolon in an HTML entity as
punctuation, it correctly performs the punctuation check on
`html.unescape(middle)`.

The bug was in mapping that decision back to the original `middle` string. The
code used the length of the unescaped, stripped prefix as an absolute index into
the original escaped text:

```python
trail = middle[len(stripped):] + trail
```

When the URL text contained an entity-like sequence such as `&lt`, the unescaped
string was shorter than the original. For `google.com/?q=1&lt!`, the code removed
only the final `!` from `middle`, but added `lt!` to `trail`, producing the
duplicated `lt!` shown in the issue.

## Files changed

`repo/django/utils/html.py`

Changed `trim_punctuation()` so the original string is sliced by the number of
trailing punctuation characters removed from the unescaped string, rather than
by the absolute length of the unescaped prefix. This preserves escaped URL text
such as `&lt` or `&lt;` inside the generated link while moving only the actual
trailing punctuation outside it.

## Assumptions and alternatives

I assumed the existing entity-aware trimming behavior is intentional because the
nearby comment explicitly says entities should not be broken by removing their
semicolon, and existing tests cover escaped query-string content such as
`&amp;` and `&lt;`.

I considered trimming punctuation directly from the original escaped string, but
that would treat the semicolon in valid entities as trailing punctuation and
could corrupt link text such as `&amp;`.

I also considered changing URL detection or quoting, but the reported output
shows URL recognition and `smart_urlquote()` are already correct once
punctuation is split into the right `middle` and `trail` parts.

No tests or code were run, per the benchmark instructions.
