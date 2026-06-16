# FVK Findings

Status: constructed, not machine-checked. These findings are based on public
intent, source inspection, and the proof obligations in
`fvk/PROOF_OBLIGATIONS.md`.

## F-001: Original Regression Resolved By V1

Input: `sympy.Symbol('s').__dict__`

Observed in the issue for version 1.7: an empty dictionary is returned.

Expected from public intent: `AttributeError`, because `Symbol` is a slotted
core object and should not inherit an instance dictionary from a parent mixin.

Cause localized by the audit: `Basic` inherits the printing mixin, and an
unslotted mixin contributes an instance dictionary to slotted subclasses.
`DefaultPrinting` is an alias for `Printable` in this checkout, so the effective
layout-bearing class is `Printable`.

V1 status: fixed. `Printable` now declares `__slots__ = ()`, and the other
classes on the modeled `Symbol` inheritance path already declare slots.

Related proof obligations: PO-001, PO-002, PO-003, PO-004, PO-005.

## F-002: Suspect Legacy Behavior Not Preserved

Input: any argument name accepted by `Symbol`, e.g. `Symbol('s')`.

Observed legacy/regressed behavior: `__dict__` exists solely because a parent
printing mixin is unslotted.

Expected from public intent: do not preserve this behavior; the issue identifies
it as the regression.

V1 status: fixed by changing the parent mixin, not by special-casing `Symbol`.

Related proof obligations: PO-001, PO-003, PO-005.

## F-003: Compatibility Boundary For Unslotted Subclasses

Input: a subclass of `Printable`/`DefaultPrinting` that omits `__slots__`.

Expected from public hint: the subclass still gets a normal instance
dictionary by Python's default rule.

V1 status: preserved. Adding empty slots to the base mixin does not add fields
or force subclasses without slots to become slotted.

Related proof obligations: PO-006, PO-007.

## F-004: No Additional Source Problem Found

Input class path audited: `Printable -> Basic -> Atom/Expr -> AtomicExpr`,
`Basic -> Boolean`, and `AtomicExpr/Boolean -> Symbol`.

Observed in source: all relevant classes except the pre-V1 printing mixin have
`__slots__` declarations.

Expected from public intent: restoring slots at the mixin should be sufficient.

V1 status: confirmed. No further source edit is justified by the FVK audit.

Related proof obligations: PO-002, PO-004, PO-005, PO-008.

## F-005: Proof And Test-Removal Honesty Boundary

Input: the FVK proof artifacts themselves.

Observed: this environment forbids running tests, Python, or K tooling.

Expected: artifacts must state exact future commands and reason about expected
outcomes without claiming machine-checked proof or deleting tests.

V1 status: no tests were run or modified; proof is constructed only.

Related proof obligations: PO-009.
