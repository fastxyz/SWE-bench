# FINDINGS

Status: constructed, not machine-checked.

## F-001: V1 fixes the reported list-to-tuple coercion

Input class:

`resolve_lookup_value([a, b], can_reuse, allow_joins, simple_col)` where
`a` and `b` are not expressions.

Observed pre-fix behavior:

The method entered the list/tuple branch, collected `resolved_values = [a, b]`,
and returned `tuple(resolved_values)`, producing `(a, b)`.

Expected behavior from public intent:

The result iterable type should match the input iterable type. A list input
should return `[a, b]`.

V1 status:

Satisfied. V1 returns `resolved_values` unchanged for non-tuple inputs in the
branch, so a built-in list input remains a list.

Classification: code bug fixed.

Proof obligations: PO-1, PO-3, PO-5.

## F-002: Exact lookup preparation depends on fixing the type before lookup construction

Input class:

An exact lookup whose right-hand side is a list value for a type-sensitive
field, such as a pickled value field.

Observed pre-fix behavior:

`build_filter()` calls `resolve_lookup_value()` before `build_lookup()`. For a
list RHS, the pre-fix method returned a tuple, so exact lookup field preparation
received the tuple instead of the caller's list.

Expected behavior from public intent:

The exact lookup should prepare the caller's list value as a list, because
type-sensitive fields can distinguish list from tuple.

V1 status:

Satisfied for built-in list inputs. The preserved list is the value passed into
lookup construction.

Classification: integration path fixed.

Proof obligations: PO-1, PO-5.

## F-003: Exact subclass preservation is under-specified

Input class:

`list` or `tuple` subclasses, for example a custom list subclass or a
`namedtuple`, passed as an exact lookup value.

Observed V1 behavior:

V1 preserves the supported built-in categories `list` and `tuple`, but it does
not claim exact subclass preservation. A list subclass would be reconstructed as
a plain list. A tuple subclass would be reconstructed as a plain tuple.

Potential expectation:

The sentence "return type should match input iterable type" could be read as
exact concrete type preservation.

Reason this is not promoted to a source change:

The issue specifically names "value of type list" and the existing method only
special-cases the `list` and `tuple` categories. Broadly switching to
`type(value)(resolved_values)` would improve many list subclasses but can
change behavior or raise for tuple subclasses whose constructors do not accept a
single iterable argument, such as `namedtuple` classes. No public evidence in
the allowed inputs resolves that tradeoff.

Classification: underspecified intent, residual risk.

Proof obligations: PO-7.

Recommended next question:

Should `resolve_lookup_value()` preserve exact concrete subclasses of list and
tuple, or only the built-in list/tuple categories already handled by the method?

## F-004: Full Django/Python execution is abstracted in the proof model

Input class:

All inputs to `resolve_lookup_value()` in the real Django runtime.

Observed proof limitation:

The mini-K model abstracts expression resolution as uninterpreted constructors
and does not model Python object identity, arbitrary subclass constructors, or
Django alias-refcount side effects.

Expected FVK honesty:

The proof may establish the constructor-preservation property over the modeled
fragment only. It must not claim full Django runtime machine verification.

V1 status:

No source change required. The abstraction still distinguishes the defect axis:
`pyList(...)` and `pyTuple(...)` are different observables, so the proof is not
vacuous for the reported bug.

Classification: proof capability gap, not a code bug.

Proof obligations: PO-1 through PO-6 within the modeled fragment.

## Proof-Derived Findings From `/verify`

No additional code bugs were found in the audited behavior space.

The only non-discharged point is F-003, exact subclass preservation. Because it
is under-specified and broadening reconstruction can introduce tuple-subclass
compatibility risk, it does not justify changing V1 in this pass.

