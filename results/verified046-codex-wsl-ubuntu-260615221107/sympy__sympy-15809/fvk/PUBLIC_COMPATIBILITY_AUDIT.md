# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed Public Symbol

- `sympy.functions.elementary.miscellaneous.MinMaxBase.__new__`, reached through
  public constructors `Min(...)` and `Max(...)`.

## Signature and Dispatch

- Signature remains `def __new__(cls, *args, **assumptions)`.
- No keyword arguments, positional parameters, virtual method calls, or return
  container shapes were added.
- No subclass override signatures are affected by the edit.

## Callsite Behavior

- Zero-argument public calls intentionally change:
  - `Min()` now returns `S.Infinity` (`oo`).
  - `Max()` now returns `S.NegativeInfinity` (`-oo`).
- Non-empty public calls enter the same filtering, collapse, local-zero, and
  object-construction path as before the edit.

## Public Tests

- Existing visible tests that assert `ValueError` for `Min()` and `Max()` are
  stale relative to the issue and are classified as SUSPECT legacy evidence.
  They should be updated when test edits are allowed, but this task forbids
  modifying test files.

Compatibility result: no source compatibility problem was found. The only API
behavior change is the requested zero-argument return value.

