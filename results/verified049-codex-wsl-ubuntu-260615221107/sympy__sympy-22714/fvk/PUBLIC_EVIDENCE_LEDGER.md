# PUBLIC_EVIDENCE_LEDGER

Status: constructed, not machine-checked.

This ledger mirrors the entries in `SPEC.md`.

- E-001: prompt reproduction under `evaluate(False)` imposes successful
  construction for real integer coordinates.
- E-002: prompt says the same expression works outside the context, imposing
  evaluation-context invariance for this validation.
- E-003: public geometry tests reject `Point(3, I)`, `Point(2*I, I)`, and
  `Point(3 + I, I)`, imposing preservation of numeric imaginary rejection.
- E-004: point docstring accepts `Point(0, x)`, imposing preservation of
  symbolic coordinate acceptance by this guard.
- E-005: point docs tie `evaluate` to float rationalization, imposing that the
  repair not change point-level simplification semantics or public API shape.
