# Public Compatibility Audit

Status: constructed from source inspection; no tests or code were run.

## Changed public symbol

`PolyElement.as_expr(self, *symbols)` keeps the same name, positional varargs
signature, return shape on success, and `ValueError` behavior on wrong arity.
The V1 change only affects which symbol tuple is passed to `expr_from_dict` on
the already-accepted same-arity branch.

## Public callsites and consumers

- Calls with no symbols keep using `self.ring.symbols`.
- Calls with same-arity symbols keep the same accepted calling convention but
  now use the supplied symbols as public intent requires.
- Calls with wrong arity still raise `ValueError`.
- `FracElement.as_expr(self, *symbols)` forwards to numerator and denominator
  `PolyElement.as_expr` and needs no signature or dispatch change.

## Overrides and subclasses

No public override or subclass dispatch change is introduced. V1 does not add a
new keyword argument, change virtual dispatch, or require consumers to accept a
new call shape.

## Compatibility finding

No compatibility blocker was found. The only public behavior change is the bug
fix identified by the issue: accepted same-arity replacement symbols are no
longer ignored.
