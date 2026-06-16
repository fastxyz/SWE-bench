# Formal Spec English

Status: constructed, not machine-checked.

## Claim C1: `ESCAPESEQ-MAP`

Starting with any finite modeled sequence `L` in the `<k>` cell as
`escapeseq(L)`, execution reaches `escapeSeq(L)`.

In English: `escapeseq` maps `conditionalEscape` over every element of `L`,
preserving element order and sequence length.

## Claim C2: `CONDITIONAL-ESCAPE-RAW`

For an unsafe modeled value `raw(S)`, `conditionalEscape(raw(S))` is
`safe(htmlEscape(S))`.

In English: unsafe values are HTML-escaped and then marked safe.

## Claim C3: `CONDITIONAL-ESCAPE-SAFE`

For an already-safe modeled value `safe(S)`, `conditionalEscape(safe(S))` is
`safe(S)`.

In English: already-safe values are not double escaped.

## Claim C4: `ESCAPESEQ-JOIN-OFF`

Starting with `joinOff(escapeseq(L), SEP)`, execution reaches
`safe(joinSafe(escapeSeq(L), SEP))`.

In English: in the issue's `autoescape off` composition, the list is escaped
item by item before the join operation concatenates it and marks the aggregate
safe.

## Source obligation S1: filter registration

The Python decorator `@register.filter(is_safe=True)` on function `escapeseq`
registers the filter under the public name `escapeseq`.

## Source obligation S2: docs coverage

The public built-in filter docs include a `.. templatefilter:: escapeseq` entry
with the issue's `autoescape off` usage pattern.
