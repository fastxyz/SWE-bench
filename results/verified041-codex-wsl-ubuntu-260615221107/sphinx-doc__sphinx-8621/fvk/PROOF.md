# Constructed Proof

Status: constructed, not machine-checked. The task forbids running tests,
Python, `kompile`, or `kprove`; the commands below are recorded for later use
only.

## Machine-Check Commands Not Run

```sh
kompile fvk/mini-keyboard.k --backend haskell
kast --backend haskell fvk/keyboard-transform-spec.k
kprove fvk/keyboard-transform-spec.k
```

Expected result after a future machine check: `#Top` for the claims in
`fvk/keyboard-transform-spec.k`.

## Claims Proved Constructively

- `STANDALONE-SEP-KEYS`: for `-`, `+`, and `^`, tokenization yields one key
  token and no separator token.
- `NORMAL-COMPOUNDS`: ordinary compound examples such as `Control+X` and
  `M-x  M-s` preserve their existing token order and separator text.
- `ADJACENT-SEP-AS-KEY`: in compounds such as `Shift-+`, `Shift--`,
  `Control++`, and `Control+^`, the punctuation character after a separator is
  a key.
- `GENERAL-POSITIONAL-TOKENIZATION`: for all `KeyboardSeq` strings, the parser
  returns alternating nonempty key parts and separator parts whose values
  concatenate to the input.
- `RUN-NODE-SHAPE`: `run()` leaves one-part tokenizations unchanged and emits
  nested literal key nodes plus text separator nodes for multi-part
  tokenizations.

## Loop Invariant for `split_keys`

Let `text` be in `KeyboardSeq`, `pos` be the current index, and `parts` be the
list accumulated at the top of the outer `while pos < len(text)` loop.

Invariant at loop entry:

1. `parts` is exactly the intended tokenization of `text[0:pos]`.
2. Concatenating the values in `parts` equals `text[0:pos]`.
3. If `parts` is nonempty, it ends in a `key` part.
4. `pos` is either `len(text)` or the start of the next separator position
   after a key has been read in the previous iteration. Equivalently, the next
   iteration starts by reading a key at the current `pos`.
5. All `key` parts in `parts` are nonempty.

The nested key-scan loop has this local invariant:

- If `text[start]` is in `{"-", "+", "^"}`, the scan advances at least once,
  so the key is nonempty and that punctuation character is classified as key
  text.
- It then consumes all following nonseparator characters.
- If `text[start]` is not a punctuation separator, it consumes the maximal
  nonempty run of nonseparator characters.

The nested whitespace-scan loop has this local invariant:

- It consumes exactly the maximal nonempty whitespace run starting at `pos`,
  preserving that run as separator text.

## Inductive Step

Assume the loop invariant holds at entry for an in-domain suffix.

Key branch:

- If the current character is a punctuation separator, V1 increments `pos`
  before the nonseparator scan. This proves the produced key is nonempty and
  proves PO-2/PO-4 for punctuation characters in key position.
- The following nonseparator scan stops exactly at `len(text)` or the next
  separator. Thus the appended `("key", text[start:pos])` is the next intended
  key token.

Separator branch:

- If `pos == len(text)`, the input ended after a key. The invariant and final
  postcondition hold.
- If `text[pos].isspace()`, V1 consumes the maximal whitespace run and appends
  it as one separator token.
- Else, `text[pos]` is a punctuation separator. If another character follows,
  V1 appends exactly that one punctuation separator token and advances to the
  next key position. If no character follows, the punctuation cannot separate
  two keys, so V1 appends it to the preceding key and terminates with a
  single-key interpretation for a trailing separator-looking character.

In every in-domain nonterminal case, `pos` strictly increases and the invariant
is re-established for the longer prefix. This is a partial-correctness proof;
termination follows informally from the strict increase of `pos`, but no
machine-checked termination claim was run.

## Base Cases

Empty text is outside `KeyboardSeq`; V1 returns no parts and `run()` leaves the
node unchanged because it checks `len(parts) <= 1`.

For one-character punctuation separator text, the first key branch consumes the
character as key text and reaches `pos == len(text)`. The result is one part, so
`run()` does not create nested children.

For one ordinary key name with no separators, the nonseparator scan consumes the
whole text as one key. The result is one part, so `run()` leaves the single
outer `kbd` behavior intact.

## `run()` Proof

`run()` obtains `parts = split_keys(node[-1].astext())`.

- If `len(parts) <= 1`, `continue` preserves the original text child. This is
  the required single-`kbd` behavior for standalone keys, including `-`, `+`,
  and `^`.
- Otherwise, `node.pop()` removes the original text child, and the following
  loop appends one child per token in order. `key` tokens become
  `nodes.literal('', value, classes=["kbd"])`; `sep` tokens become
  `nodes.Text(value)`.

Because PO-5 proves all in-domain key token values are nonempty, `run()` cannot
emit blank nested key nodes for the public intent domain.

## Findings Summary

F-1 and F-2 are closed by V1. F-3 confirms ordinary compound behavior remains
covered. F-4 records an underspecified malformed-input ambiguity that does not
justify a source change. F-5 records the constructed, not machine-checked,
status.

## Test-Redundancy Recommendation

No tests were edited. If the K claims are later machine-checked to `#Top`,
point tests that assert only the in-domain cases covered above would be
subsumed by the proof. Until then, all tests should be kept.
