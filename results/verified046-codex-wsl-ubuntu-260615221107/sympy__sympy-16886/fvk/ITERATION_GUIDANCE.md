# Iteration Guidance

Status: V1 stands unchanged.

## Decision

No additional source edits are justified by the FVK audit. The V1 source change
corrects the public-intent table entry and, because `char_morse` is derived from
`morse_char`, also corrects default encoding.

## Next Code Iteration

- Keep `repo/sympy/crypto/crypto.py` unchanged from V1.
- Do not add a separate hand-written `char_morse` patch; PO-2 shows that would
  duplicate derived state.
- Do not change tests in this task. A normal development follow-up should add
  explicit digit coverage for `encode_morse("1")` and `decode_morse(".----")`.
- Do not remove tests based on this constructed proof. Test removal is
  conditional on running the emitted K commands and receiving `#Top`.

## Residual Risk

- The proof is constructed, not machine-checked.
- The mini semantics models the relevant finite-map and one-character
  encode/decode path, not all Python behavior of the full functions.
- No runtime validation was performed because the task forbids execution.

