# FVK Proof

Status: constructed, not machine-checked. No tests, Python, `kompile`,
`kast`, or `kprove` were run.

## Claim

For every in-domain printable-ASCII string value `v` whose `Card` image uses
the FITS `CONTINUE` convention:

```
Card.fromstring(str(Card(k, v, c))).value == Card(k, v, c).value
```

for the quote-preservation cases described in the issue, including:

- `v = "x" * n + "''"` where the doubled quote appears at the end of the
  value;
- `v = "x" * n + "''" + "x" * 10`;
- `v = "x" * 100 + "'' aaa"` with a comment, where a space follows the doubled
  quote before more text.

The proof covers value preservation and the frame condition that comments and
public APIs are not changed by V1.

## Constructed K Artifacts

The accompanying files are:

- `fvk/mini-fits-card.k`: a mini semantics for the audited string-processing
  fragment.
- `fvk/fits-card-spec.k`: K-style claims for the round-trip and frame
  obligations.

The intended machine-check commands, not executed in this task, are:

```sh
kompile fvk/mini-fits-card.k --backend haskell
kast --backend haskell fvk/fits-card-spec.k
kprove fvk/fits-card-spec.k
```

Expected result after a successful future machine check: `#Top`.

## Proof Sketch

Let `escape` double each logical single quote and let `unescape` replace each
doubled quote with one logical quote.

By PO1, `_format_long_image()` computes escaped text:

```
e = escape(v)
```

and splits it into ordered raw chunks:

```
p_1, ..., p_n
p_1 + ... + p_n == e
```

Each non-final physical value card, and each final value card followed by
comment cards, carries an ampersand continuation marker. By the documented
`CONTINUE` convention and PO3, that marker is representation-only.

For each physical value/comment field `vc_i`, V1 uses:

```
_strg_comment_RE.fullmatch(vc_i)
```

instead of a prefix `match()`. Therefore a parse that closes the FITS string at
the quote before a remaining suffix is not accepted. In the issue's
`"'' aaa"` family, a premature quote choice would leave continuation text
unconsumed, so it fails PO2. The accepted match must consume the whole field and
therefore exposes the actual raw escaped payload plus any trailing continuation
marker.

V1 then applies:

```
r_i = strip_continue(raw_payload_i)
```

where `strip_continue` trims padding and removes one final `&` marker. It does
not unescape quotes. Thus:

```
r_i == p_i
```

for every value chunk.

By concatenation:

```
r_1 + ... + r_n == p_1 + ... + p_n == e
```

By PO4, `_split()` synthesizes the value/comment string:

```
"'" + e + "' / " + joined_comments
```

The subsequent `_parse_value()` call parses that synthesized string and applies
the existing single unescape step:

```
re.sub("''", "'", e) == unescape(e) == v
```

That proves PO5 and, by composition, PO6.

## Why V1 Stands

The V1 code changed exactly the two operations needed by the proof:

1. `_strg_comment_RE.match(vc)` became `_strg_comment_RE.fullmatch(vc)`,
   discharging PO2 and resolving F2.
2. Per-chunk `replace("''", "'")` was removed, discharging PO3 and resolving
   F1.

No further code edit is justified by the FVK findings. F3 confirms the frame
conditions, and F4 is explicitly a broader malformed-string parser risk outside
the public issue's intent.

## Residual Risk

This proof is partial correctness over the audited parsing/formatting path. It
does not prove termination, full FITS parser conformance, or behavior for
malformed strings outside the existing grammar. It also remains constructed, not
machine-checked, because the task forbids executing K tooling.

## Test Guidance

No test files were edited. No test removal is recommended. If tests could be
added in a normal development setting, useful public tests would cover:

- a long value ending in `''`;
- a long value containing `''` before more text;
- `x * 100 + "'' aaa"` with a comment;
- existing long-value comment continuation cases to preserve the frame
  condition.
