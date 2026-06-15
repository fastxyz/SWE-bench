# Findings

Status: constructed, not machine-checked.

## F-001: Fixed bug, left mask plus maskless right operand reached callable

- Classification: code bug fixed by V1.
- Input: `self.mask = Present(1)`, `operand.mask = NoMask`,
  `handle_mask = callable`.
- Pre-V1 observed: the helper skipped the one-mask copy branch and invoked
  `handle_mask(self.mask, None)`, which can raise `TypeError` for
  `numpy.bitwise_or`.
- Expected: return `Copy(self.mask)` without invoking `handle_mask`.
- Evidence: L1, L2, L7.
- Proof obligations: PO-3, PO-6.
- V1 audit result: fixed by `operand is None or operand.mask is None`.

## F-002: Fixed bug, boolean masks could become object masks with `None`

- Classification: code bug fixed by V1.
- Input: `self.mask = Present(bool_mask)`, `operand.mask = NoMask`,
  default callable `numpy.logical_or`.
- Pre-V1 observed from issue discussion: result could include `None` entries and
  become an object mask.
- Expected: copy the boolean mask as the only present mask.
- Evidence: L5, L7.
- Proof obligations: PO-3, PO-7.
- V1 audit result: fixed by the same left-only mask short-circuit.

## F-003: Confirmed, integer bitmask values remain in domain

- Classification: confirmed behavior.
- Input: `self.mask = Present(integer_bitmask)`, `operand.mask = NoMask`,
  `handle_mask = numpy.bitwise_or`.
- Expected: copy the integer bitmask; do not coerce to boolean and do not create
  an all-false missing mask.
- Evidence: L2, L6.
- Proof obligations: PO-3, PO-7.
- V1 audit result: confirmed, because the branch returns `deepcopy(self.mask)`.

## F-004: No compatibility finding requiring additional source edits

- Classification: compatibility confirmation.
- Input: public arithmetic callers and subclass override surface for
  `_arithmetic_mask`.
- Expected: no signature or dispatch change.
- Evidence: public compatibility audit.
- Proof obligations: PO-8.
- V1 audit result: confirmed. No V2 source edit is justified beyond V1.

## Proof-derived findings from `/verify`

No unresolved code findings were produced by the constructed proof. The proof is
not machine-checked because this benchmark forbids running K tooling; therefore
test removal or proof-confidence upgrades are conditioned on later execution of
the commands in `fvk/PROOF.md`.
