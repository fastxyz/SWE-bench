# Iteration Guidance

Status: constructed, not machine-checked.

## Code decision

Keep V1 unchanged. The FVK audit found that V1 discharges the relevant proof
obligations:

- PO-1: no-symbol default still uses ring symbols.
- PO-2: same-arity supplied symbols are preserved.
- PO-3: wrong arity still raises `ValueError`.
- PO-4: `expr_from_dict` uses the preserved tuple positionally.
- PO-5: `FracElement.as_expr` forwarding benefits from the same correction.
- PO-6: public API compatibility is preserved.

## Suggested future tests

Do not edit tests in this task. For a future normal development pass, add public
coverage for:

- `PolyElement.as_expr(u, v, w)` where `u, v, w` differ from the ring symbols;
- `FracElement.as_expr(u, v, w)` for the same distinct-symbol forwarding path;
- existing wrong-arity rejection, without relying on the exact message.

These are derived from F-1 and F-2.

## Optional future clarification

F-3 notes that the existing wrong-arity message says "not enough symbols" even
for too many symbols. Public intent only requires an error, so V1 intentionally
does not change the message. A future API-polish issue could clarify whether the
message should be made arity-neutral.
