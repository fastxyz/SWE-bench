# FVK Notes

## Decision

V1 stands unchanged. The audit confirmed that the existing source change
discharges the public issue and the proof obligations. No additional production
edit is justified.

## Trace to findings and proof obligations

F1 maps to PO-2, PO-3, and PO-4. The original failure was `Q() & Exists(...)`
raising `TypeError` because `Q._combine()` rejected every non-`Q` operand. V1
fixes that by checking the public boolean-expression marker `conditional` and
wrapping accepted non-`Q` operands as `Q(other)`.

F2 maps to PO-5 and PO-7. The FVK pass made the empty-left path explicit:
`Q() & Exists(...)` reaches `other.deconstruct()` after wrapping `Exists`.
Keeping V1's `Q.deconstruct()` change is therefore required; otherwise the
expression child would be treated as a lookup tuple during cloning.

F3 maps to PO-2 and PO-9. The audit checked the compatibility constraint from
existing `Q` tests: plain non-conditional objects still raise `TypeError`.
Because V1 raises before wrapping when `conditional` is false, no additional
guard or API change is needed.

F4 maps to PO-1 through PO-9. Both public hinted cases,
`Q(...) & Exists(...)` and `Q(...) | Exists(...)`, are covered by the formal
claims, and the compatibility audit found no changed signatures or unhandled
public consumers.

## Alternatives rejected

Adding reflected `__rand__` or `__ror__` remains rejected. PO-3 localizes the
operative failure to `Q._combine()` because `Q.__and__()` raises directly; a
reflected method on `Exists` would not be reached for the reported expression.

Special-casing `Exists` remains rejected. PO-1 and PO-8 identify the intended
domain as Django conditional expressions compatible with query filtering, and
`Exists` is one member of that domain.

Narrowing the fix further was not required by the findings. The audited contract
does not cover arbitrary marker objects with `conditional = True`; it covers
Django boolean expressions such as `Exists`. V1 matches the existing ORM pattern
used by boolean expression combination.

## Verification caveat

No tests, Python code, or K tooling were run. The FVK proof is constructed, not
machine-checked, and test removal is not recommended.

