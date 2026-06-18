# Public Compatibility Audit

Status: constructed, not machine-checked.

Changed symbol: `BlockMatrix._blockmul(self, other)`.

## API Surface

| Compatibility axis | Observation | Status |
|---|---|---|
| Method name | Unchanged. | Compatible. |
| Method signature | Still `_blockmul(self, other)`. | Compatible. |
| Return branch for compatible `BlockMatrix` operands | Still returns a `BlockMatrix`; scalar zero result entries are now shaped `ZeroMatrix` entries. | Compatible with block-matrix invariant and issue intent. |
| Return branch for non-`BlockMatrix` operands | Still falls through to `self * other`. | Compatible; covered by `BLOCKMUL-NONBLOCK-FALLBACK`. |
| Return branch for incompatible `BlockMatrix` operands | Still falls through to `self * other`. | Compatible; covered by `BLOCKMUL-INCOMPATIBLE-FALLBACK`. |

## Static Callsite And Override Search

Static source search found:

- `BlockMatrix._blockmul` definition in `blockmatrix.py`.
- `BlockDiagMatrix._blockmul` override delegates to `BlockMatrix._blockmul` for
  non-`BlockDiagMatrix` cases.
- `bc_matmul` calls `_blockmul` for adjacent block-matrix factors and for
  one-by-one wrapping of mixed block/non-block products.
- Public in-repo tests assert non-`BlockMatrix` fallback behavior with
  `X._blockmul(M).is_MatMul`.

V1 changes no virtual dispatch signature and adds no new arguments, so public
overrides do not need changes.

## Compatibility Decision

No compatibility finding forces a V2 source edit. The only changed observable is
the internal type of exact zero product entries in a `BlockMatrix`, and that
observable is precisely the public issue's defect mechanism.
