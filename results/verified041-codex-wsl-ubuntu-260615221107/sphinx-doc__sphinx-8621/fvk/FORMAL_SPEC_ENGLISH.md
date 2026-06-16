# Formal Spec in English

## `STANDALONE-SEP-KEYS`

For input `"-"`, `"+"`, or `"^"`, the tokenizer returns exactly one key token
whose value is that character.

## `NORMAL-COMPOUNDS`

For ordinary compound key strings, punctuation or whitespace in separator
position remains separator text. `Control+X` becomes key `Control`, separator
`+`, key `X`; `M-x  M-s` becomes key `M`, separator `-`, key `x`, separator two
spaces, key `M`, separator `-`, key `s`.

## `ADJACENT-SEP-AS-KEY`

When a punctuation separator character appears immediately after a separator,
it is in key position and becomes key text. Examples include `Shift-+`,
`Shift--`, `Shift-^`, `Control++`, `Control+-`, and `Control+^`.

## `GENERAL-POSITIONAL-TOKENIZATION`

For every finite string in the `KeyboardSeq` domain, tokenization returns
alternating key and separator tokens. Each key token is nonempty, each separator
token is a punctuation separator or whitespace run, and concatenating token
values reconstructs the input exactly.

## `RUN-NODE-SHAPE`

For one-token results, `KeyboardTransform.run()` leaves the original kbd
literal node unchanged. For multi-token results, it replaces the original text
child with nested kbd literal nodes for key tokens and text nodes for separator
tokens in the same order.

## Compatibility Claim

The formalized behavior changes only the HTML kbd tokenizer. Public role
registration, builder setup, non-HTML writers, and ordinary compound examples
are unchanged.
