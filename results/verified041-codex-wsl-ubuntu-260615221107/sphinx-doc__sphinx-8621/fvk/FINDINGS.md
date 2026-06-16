# FVK Findings

Status: V1 confirmed for the public intent. No production-code edit was made
after the FVK audit.

## F-1: Closed Bug, Standalone Separator Keys

Input: `:kbd:`-``, `:kbd:`+``, and `:kbd:`^``.

Pre-V1 observed behavior, from the issue: the punctuation character was treated
as a separator, producing blank nested `<kbd>` children around it.

Expected behavior, from INT-1 and INT-3: the punctuation character is the key
itself, so the transform should leave a single key token and `run()` should not
replace it with nested children.

V1 status: closed. `split_keys()` consumes a punctuation separator as a key
when it appears at key position, returns one `key` part for each standalone
case, and `run()` leaves one-part results unchanged. Covered by PO-2 and the
`STANDALONE-SEP-KEYS` claim.

## F-2: Closed Bug, Separator Character Inside Compound Keystroke

Input: `:kbd:`Shift-+`` and the derived family `Shift--`, `Shift-^`,
`Control++`, `Control+-`, and `Control+^`.

Pre-V1 observed behavior, from the issue: the second punctuation character was
treated as another separator, producing blank nested `<kbd>` children.

Expected behavior, from INT-2 and INT-3: after a separator has been consumed,
the next punctuation separator character is in key position and must be emitted
as a nonempty key token.

V1 status: closed. `split_keys()` alternates key and separator positions, so the
punctuation character after the separator is consumed by the next key scan.
Covered by PO-4 and the `ADJACENT-SEP-AS-KEY` claim.

## F-3: Confirmed Frame, Existing Compound Syntax

Input: `:kbd:`Control+X`` and `:kbd:`M-x  M-s``.

Expected behavior, from INT-4 and INT-5: ordinary compound sequences continue
to split on `+`, `-`, and whitespace separators, preserving separator text in
the output.

V1 status: confirmed. The first scan consumes ordinary key names, the separator
branch consumes punctuation or whitespace separators, and `run()` emits the
same nested-node shape as before for these in-domain compounds. Covered by PO-3
and PO-6.

## F-4: Non-Blocking Ambiguity, Malformed Adjacent Separators

Input example: `:kbd:`Shift- +``.

Observed V1 reasoning: this has a punctuation separator followed immediately by
a whitespace separator, so it does not match the `KeyboardSeq` domain in
`fvk/SPEC.md`; V1 may still produce an empty key token for this malformed
shape.

Expected behavior: underspecified by the public issue and Sphinx role docs. The
issue requires distinguishing `-`, `+`, and `^` when they are keystrokes; it
does not define recovery for adjacent mixed separators or missing key text.

Status: no source change. This ambiguity does not block V1 because every
publicly specified member of the separator-as-key family is covered. If this
input should be accepted, the next iteration should first clarify whether
adjacent separators are invalid syntax, separator text to preserve, or an
implicit request to trim whitespace.

## F-5: Proof Status Is Constructed, Not Machine-Checked

The FVK proof package includes K-style artifacts and exact commands, but the
task forbids running K tooling. Therefore the proof is a constructed proof, not
a machine-checked `#Top` result. This does not change the code decision; it only
conditions any future test-removal recommendation on running the emitted
commands.
