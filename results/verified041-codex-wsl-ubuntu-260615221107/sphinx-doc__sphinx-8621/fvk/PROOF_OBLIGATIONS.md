# Proof Obligations

Status: constructed, not machine-checked.

## PO-1: Intent-Derived Domain

For finite `text` in `KeyboardSeq`, tokenization starts in key position and
alternates between key and separator positions.

Justification: INT-2 says the algorithm must distinguish separator characters
by position. The domain is not copied from V1; it is derived from the role's
"sequence of keystrokes" intent and the issue's separator/key distinction.

Status: discharged by the loop invariant in `fvk/PROOF.md`.

## PO-2: Standalone Separator Characters Are Keys

For each `c` in `{"-", "+", "^"}`, `split_keys(c)` returns exactly
`[("key", c)]`.

Consequence for `run()`: because the result has one part, the original literal
text remains in the outer `kbd` node and no blank nested key nodes are emitted.

Status: discharged. Supports F-1.

## PO-3: Ordinary Compound Keystrokes Remain Compound

For key names that do not begin at key position with punctuation separators,
separators in separator position split the sequence:

- `Control+X` tokenizes as `key("Control"), sep("+"), key("X")`
- `M-x  M-s` tokenizes as `key("M"), sep("-"), key("x"), sep("  "), key("M"), sep("-"), key("s")`

Consequence for `run()`: output order, separator text, and nested key text are
unchanged for existing normal compound behavior.

Status: discharged. Supports F-3.

## PO-4: Separator-Looking Characters in Key Position Are Keys

For any in-domain prefix `Key Sep`, if the next character is in
`{"-", "+", "^"}`, that character starts the next key and is not consumed as a
separator.

Examples:

- `Shift-+` tokenizes as `key("Shift"), sep("-"), key("+")`
- `Shift--` tokenizes as `key("Shift"), sep("-"), key("-")`
- `Control++` tokenizes as `key("Control"), sep("+"), key("+")`
- `Control+^` tokenizes as `key("Control"), sep("+"), key("^")`

Status: discharged. Supports F-2.

## PO-5: No Empty Key Tokens In Domain

For every `text` in `KeyboardSeq`, every returned `key` part has nonempty text.

Status: discharged for the intent-derived domain. Malformed adjacent separators
remain outside the domain and are recorded in F-4.

## PO-6: HTML Node Shape Preservation

For a `nodes.literal` with class `kbd` and one text child:

- a zero- or one-part tokenization is left unchanged;
- a multi-part tokenization becomes nested `nodes.literal` children for key
  parts and `nodes.Text` children for separator parts;
- child order and text concatenate back to the original input.

Status: discharged by inspection of `run()` and the tokenization obligations.

## PO-7: Compatibility Frame

The source change must not alter role registration, builder selection, writer
classes, LaTeX behavior, public command APIs, or existing ordinary compound
HTML behavior.

Status: discharged by source inspection. `setup()` and `run()` signatures are
unchanged; the new helper is internal to `KeyboardTransform`; existing compound
examples are covered by PO-3.

## PO-8: Honesty Gate

The proof package must be labeled constructed, not machine-checked, and must
record the commands that would be run in an execution-capable environment.

Status: discharged in `fvk/PROOF.md`.
