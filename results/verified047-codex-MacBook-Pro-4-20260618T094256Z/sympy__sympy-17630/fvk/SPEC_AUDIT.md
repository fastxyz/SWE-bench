# Spec Audit

Status: constructed, not machine-checked.

| Intent obligation | Formal coverage | Audit result |
|---|---|---|
| Block entries must be matrix-shaped. | `BLOCKMUL-REPEATED-SAFE`, `BLOCKMUL-COMPATIBLE-ZERO-ENTRY`. | Pass. |
| Compatible `BlockMatrix` operands should return a block product. | `blockMul(A, block(B)) => product(A, B)` in `mini-blockmatrix.k`, with product-entry claims. | Pass. |
| Exact scalar zero from raw block multiplication must become shaped `ZeroMatrix`. | `NORMALIZE-SCALAR-ZERO`, `BLOCKMUL-COMPATIBLE-ZERO-ENTRY`. | Pass. |
| Matrix product entries must be preserved. | `NORMALIZE-MATRIX-PRESERVE`, `BLOCKMUL-COMPATIBLE-MATRIX-ENTRY`. | Pass. |
| Result row sizes come from the left operand. | `BLOCKMUL-RESULT-ROW-SHAPE`. | Pass. |
| Result column sizes come from the right operand. | `BLOCKMUL-RESULT-COL-SHAPE`. | Pass. |
| Repeated multiplication must not fail from scalar zero entries lacking shape. | `BLOCKMUL-REPEATED-SAFE`. | Pass. |
| Non-`BlockMatrix` fallback behavior must remain unchanged. | `BLOCKMUL-NONBLOCK-FALLBACK`. | Pass. |
| Incompatible `BlockMatrix` fallback behavior must remain unchanged. | `BLOCKMUL-INCOMPATIBLE-FALLBACK`. | Pass. |

## Adequacy Decision

The formal English matches the public issue intent and the relevant source
contracts. No formal obligation fails or remains ambiguous in a way that would
force a source edit beyond V1.

## Limits

The proof has not been machine-checked because this session forbids running
`kompile`, `kprove`, Python, or tests. The audit result is therefore
constructed, not machine-checked.
