# FVK Proof Obligations

Status legend:

- Discharged by source inspection: proven by reading the allowed source files.
- Discharged by constructed proof: proven in the K-style model, but not
  machine-checked because K tooling must not be run in this environment.
- Boundary: explicitly outside what this run can prove.

## PO-001: Intent Adequacy

Statement: the formal postcondition must be `hasInstanceDict(Symbol) == false`,
not the regressed behavior where `Symbol('s').__dict__` returns `{}`.

Evidence: SPEC ledger I-001 and I-002.

Status: discharged by adequacy audit in `fvk/SPEC.md`.

Findings: F-001, F-002.

## PO-002: Property-Complete Abstraction

Statement: the formal model must distinguish classes/instances with an
inherited instance dictionary from those without one.

Evidence: the issue's only observable is presence or absence of `__dict__`.

Status: discharged by `mini-python-slots.k`, where `hasInstanceDict(C)` is the
observable.

Findings: F-001, F-004.

## PO-003: Correct Changed Class

Statement: the class receiving `__slots__ = ()` must be the layout-bearing
printing mixin used by `Basic`.

Evidence: `DefaultPrinting = Printable` in `sympy/printing/defaults.py` and
`class Basic(Printable, ...)` in `sympy/core/basic.py`.

Status: discharged by source inspection. V1 changed
`sympy/core/_print_helpers.py`, where `Printable` is defined.

Findings: F-001, F-002.

## PO-004: Printable Own-Dict Removal

Statement: `Printable` must not provide an instance dictionary.

Evidence: public hint asks for empty slots on `DefaultPrinting`; in this source
that alias points to `Printable`.

Status: discharged by source inspection of V1:
`repo/sympy/core/_print_helpers.py` defines `Printable.__slots__ = ()`.

Findings: F-001, F-004.

## PO-005: Symbol Inheritance Path Has No Other Dict Contributor

Statement: every modeled base on the `Symbol` path must have `EmptySlots` or
`NamedSlots`, so no base recursively contributes an instance dictionary.

Evidence: source shows slots on `Basic`, `Atom`, `Expr`, `AtomicExpr`,
`Boolean`, `Symbol`, and `EvalfMixin`.

Status: discharged by source inspection and constructed proof claim
`hasInstanceDict(Symbol) => false`.

Findings: F-001, F-004.

## PO-006: Compatibility For Unslotted Subclasses

Statement: subclasses of `Printable`/`DefaultPrinting` that omit `__slots__`
must still receive their own instance dictionary.

Evidence: public hint in the issue discussion.

Status: discharged by constructed proof claim
`hasInstanceDict(ExternalNoSlotsSubclass) => true`.

Findings: F-003.

## PO-007: No Public Method/API Shape Change

Statement: the fix must not alter public printing method signatures, import
paths, or return protocols.

Evidence: source diff changes only `Printable.__slots__`.

Status: discharged by source inspection.

Findings: F-003.

## PO-008: Minimality

Statement: the source fix should be scoped to the parent mixin that introduced
the dictionary and should not remove slots project-wide or special-case
`Symbol`.

Evidence: public issue localizes the regression to the printing parent; source
shows `DefaultPrinting` is an alias for `Printable`.

Status: discharged. V1 is a one-line source change and no further source edit
was found necessary.

Findings: F-004.

## PO-009: Honesty Boundary

Statement: no tests, Python imports, or K framework commands may be run; proof
must be labeled constructed, not machine-checked.

Evidence: user task forbids execution and FVK docs require the honesty gate.

Status: boundary recorded. The expected commands are written in
`fvk/PROOF.md`, not executed.

Findings: F-005.
