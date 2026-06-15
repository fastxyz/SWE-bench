# FVK Findings

Status: constructed, not machine-checked. Findings are from public intent,
static source reading, and proof-obligation construction only.

## F-01: V1 Could Raise On Read-Only Descriptor Doc Assignment

Classification: code bug in V1, fixed in V2.

Input shape: a class using `InheritDocstrings` defines a public data descriptor
`x` with `x.__doc__ is None`, the first base class has `x.__doc__ == "base doc"`,
and the subclass descriptor rejects assignment to `__doc__` with
`AttributeError` or `TypeError`.

V1 observed by static symbolic path: `inspect.isdatadescriptor(x)` makes the
member eligible; the first base member is found; `x.__doc__ = "base doc"` is
executed unguarded; class creation aborts if the descriptor doc is read-only.

Expected: the property case must be fixed, but broadening the metaclass to all
data descriptors must not make class creation fail for descriptors whose docs
cannot be mutated. Such a member should be left unchanged.

Resolution: V2 wraps the assignment in `try/except (AttributeError, TypeError)`
and leaves the descriptor unchanged on assignment failure.

Trace: PO-07.

## F-02: Core Property Docstring Bug Is Discharged By V2

Classification: resolved issue behavior.

Input shape: base class has a public property `p` with docstring `"base doc"`;
subclass redefines `p` with `@property` and no docstring.

Pre-fix observed from source: the subclass `property` object is not a function,
so `inspect.isfunction(p)` is false and the inheritance block is skipped.

Expected: `Subclass.p.__doc__ == "base doc"` because the public issue requires
properties to receive inherited docs when redefined without setting a docstring.

Resolution: V2 treats data descriptors as inheritable members and copies the
first inherited docstring found by MRO.

Trace: PO-01, PO-03, PO-04.

## F-03: Function Behavior Must Be Preserved

Classification: compatibility check, discharged by V2.

Input shape: base class has a documented public method; subclass redefines the
method without a docstring.

Expected: existing method doc inheritance continues to work.

Resolution: V2 keeps functions eligible and keeps dynamic `getattr` lookup for
function members, preserving V1's method path.

Trace: PO-02.

## F-04: Explicit Subclass Docstrings Must Not Be Overwritten

Classification: compatibility check, discharged by V2.

Input shape: subclass member is a function or data descriptor with an explicit
docstring.

Expected: the explicit subclass docstring wins.

Resolution: V2 preserves the existing `val.__doc__ is None` guard.

Trace: PO-05.

## F-05: Proof Is Constructed Only

Classification: proof/tooling limitation.

No `kompile`, `kast`, `kprove`, tests, or Python code were executed. The proof
is a constructed argument over the mini semantics, not a machine-checked result.
Tests should not be removed based on this audit.

Trace: PO-10.
