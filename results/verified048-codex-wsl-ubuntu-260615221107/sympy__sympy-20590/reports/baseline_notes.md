# Baseline Notes

## Root Cause

`Basic` inherits from `Printable`, the shared printing mixin defined in
`sympy/core/_print_helpers.py`. `Printable` did not define `__slots__`, so it
provided a normal instance `__dict__`. Even though `Basic`, `Expr`, `Atom`, and
`Symbol` define slots, the unslotted base class meant `Symbol` instances still
inherited an instance dictionary.

In this checkout, `sympy.printing.defaults.DefaultPrinting` is a compatibility
alias for `Printable`, so fixing the shared base also fixes users that import
`DefaultPrinting`.

## Changed Files

`repo/sympy/core/_print_helpers.py`

Added `__slots__ = ()` to `Printable`. The class has no per-instance state and
only supplies printing hooks, so an empty slots declaration preserves its
behavior while preventing it from adding `__dict__` to slotted subclasses such
as `Symbol`.

`reports/baseline_notes.md`

Added this report to document the root cause, implementation, assumptions, and
rejected alternatives.

## Assumptions

The intended behavior is that `Symbol('s').__dict__` should raise
`AttributeError`, matching the existing slot declarations on `Basic` and
`Symbol`.

The printing mixin does not need instance attributes. Its methods compute
representations dynamically and do not store state on `self`.

## Alternatives Considered

Adding `__slots__ = ()` to `sympy.printing.defaults.DefaultPrinting` was
rejected because `DefaultPrinting` is only an alias to `Printable` here, not an
independent class.

Removing slots from core expression classes was rejected because it would be a
larger behavior change and would not address the reported regression in the
least invasive way.

Changing `Symbol` specifically was rejected because the inherited `__dict__`
comes from the shared printing base and can affect other slotted subclasses of
`Printable`.
