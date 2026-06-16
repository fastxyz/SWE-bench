# Proof Obligations

Status: constructed, not machine-checked.

## PO-01: Domain Adequacy

The formal domain must include zero-valued Decimal inputs with explicit scale
`S >= 0` and integer precision `P = 0`, covering both reported calls:
`floatformat('0.00', 0)` and `floatformat(Decimal('0.00'), 0)`.

Justification: E-01, E-02, E-03.

## PO-02: Decimal Context Precision Lower Bound

For every `P >= 0` and `S >= 0`, V1 must construct a Decimal context precision
`prec >= 1`.

Formal claim: C-01.

Discharge argument: `prec = max(1, P + 2 - S)`, and `max(1, X) >= 1` for all
integers `X`.

## PO-03: Reported Output for Precision 0

For every zero Decimal scale `S >= 0`, `floatformat(zero(S), 0)` must return
`"0"` rather than raising.

Formal claim: C-02.

Discharge argument: PO-02 makes context construction valid; quantizing a zero
Decimal at exponent `0` yields zero; the existing formatting path with
`decimal_pos=0` renders integer-form `"0"`.

## PO-04: Frame Existing Valid-Precision Behavior

For any path where the old raw precision `raw = P + units + 1` is already
`>= 1`, V1 must not change the precision value.

Discharge argument: `max(1, raw) = raw` when `raw >= 1`.

## PO-05: Negative Precision Zero Branch

For zero-valued inputs with `P < 0`, the existing early return must remain
unchanged and must not depend on the Decimal context precision calculation.

Formal claim: C-03.

Discharge argument: the early `if not m and p < 0` branch returns before the
edited `prec` assignment.

## PO-06: Public Compatibility

The fix must preserve the public function signature, return shape, suffix
parsing protocol, and known callsites.

Discharge argument: V1 changes only the local `prec` expression. No signature,
callsite, import, or return-shape changes were made.

## PO-07: Honesty Gate

The proof artifacts must emit exact K commands and remain labeled
constructed, not machine-checked, because no K tooling is run in this session.

Discharge argument: commands are recorded in `fvk/PROOF.md`; no tests, Python,
or K commands were executed.
