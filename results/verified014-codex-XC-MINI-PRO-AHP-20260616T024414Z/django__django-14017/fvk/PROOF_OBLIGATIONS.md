# Proof Obligations

Status: constructed, not machine-checked.

## Obligations

PO-1: Adequacy. The formal claims must match the public intent: `Q`/`Exists`
pairs are valid for `&` and `|` in either order, and plain non-conditional
objects remain invalid.

PO-2: Non-conditional rejection. For `other` with no truthy `conditional`,
`Q._combine(self, other, conn)` raises `TypeError(other)`.

PO-3: Conditional acceptance. For conditional `other`, including `Exists`,
`Q._combine()` does not raise at the type guard solely because `other` is not a
`Q`.

PO-4: Wrapping. A conditional non-`Q` operand is converted to `Q(other)` before
empty checks and before children are added to the combined node.

PO-5: Empty-left identity. For empty `self` and conditional non-empty `other`,
`Q._combine()` returns a reconstructed `Q(other)` rather than raising during
`other.deconstruct()`.

PO-6: Non-empty combination. For non-empty `self` and conditional non-empty
`other`, `Q._combine()` returns a `Q` with connector `conn` and with both
operands represented in the children.

PO-7: Expression-safe `deconstruct()`. `Q.deconstruct()` serializes a single
non-tuple, non-`Q` child as positional args, and still serializes a single
lookup tuple child as kwargs.

PO-8: Query compatibility. The result of combining `Q` with `Exists` remains
compatible with `Query.build_filter()` because `Exists` is a conditional
expression with `resolve_expression`.

PO-9: Public compatibility. The fix does not change public method signatures,
does not modify tests, and preserves existing `Q` behavior for ordinary lookup
children and non-conditional operands.

## Discharge summary

| Obligation | Discharge |
| --- | --- |
| PO-1 | `INTENT_SPEC.md`, `FORMAL_SPEC_ENGLISH.md`, and `SPEC_AUDIT.md` all align. |
| PO-2 | `query_utils.py` lines 42-44. |
| PO-3 | `query_utils.py` lines 42-46. |
| PO-4 | `query_utils.py` lines 45-46. |
| PO-5 | `query_utils.py` lines 53-55 plus lines 90-95. |
| PO-6 | `query_utils.py` lines 57-61. |
| PO-7 | `query_utils.py` lines 90-95. |
| PO-8 | `expressions.py` `Exists.output_field = BooleanField()` and `query.py` conditional expression branch. |
| PO-9 | `PUBLIC_COMPATIBILITY_AUDIT.md`. |

