# Proof Obligations

Status: constructed, not machine-checked.

## PO-1: Importable Class-Bound Method Uses Class Qualified Name

Precondition: `value.__self__` is a class `klass`; `klass.__module__ = M`;
`klass.__qualname__ = Q`; `value.__name__ = N`; `"<" not in Q`.

Postcondition: `serialize()` returns
`("%s.%s.%s" % (M, Q, N), {"import %s" % M})`.

Evidence: E-1, E-2, E-5. Finding: F-001.

Status: discharged by the V2 class-bound importable branch.

## PO-2: Local Class-Bound Method Is Rejected

Precondition: `value.__self__` is a class `klass`; `klass.__module__ = M`;
`klass.__qualname__ = Q`; `value.__name__ = N`; `"<" in Q`.

Postcondition: `serialize()` raises
`ValueError("Could not find function %s in %s.\n" % (N, M))`.

Evidence: E-3, E-4. Finding: F-002.

Status: discharged by the V2 local-marker guard in the class-bound branch.

## PO-3: Top-Level Class-Bound Method Compatibility

Precondition: PO-1 holds and `Q == klass.__name__`.

Postcondition: the serialized path is identical to the historical top-level
class-bound method path because `__qualname__` and `__name__` are equal.

Evidence: compatibility frame condition from E-2 and Django's existing
top-level import style. Finding: F-001.

Status: discharged algebraically from PO-1.

## PO-4: Lambda Rejection Is Uniform

Precondition: `value.__name__ == "<lambda>"`.

Postcondition: `serialize()` raises
`ValueError("Cannot serialize function: lambda")` before any successful
serialization branch.

Evidence: E-5. Finding: F-003.

Status: discharged by moving the lambda check before the class-bound branch.

## PO-5: Non-Class-Bound Callable Frame Condition

Precondition: `value.__self__` is absent or is not a class, and PO-4 does not
apply.

Postcondition: the existing non-class-bound logic is unchanged: no-module values
raise, importable functions serialize as `module.__qualname__`, and local
functions raise.

Evidence: E-3, E-4 and unchanged code after the class-bound branch. Finding:
F-004.

Status: discharged by branch exclusion; V2 edits do not alter the non-class-bound
body.

## PO-6: Public Compatibility

Precondition: callers invoke `FunctionTypeSerializer.serialize()` through the
existing serializer registry.

Postcondition: method signature, successful return shape, and import-set shape
are unchanged; no test files are modified.

Evidence: `PUBLIC_COMPATIBILITY_AUDIT.md`.

Status: discharged by source inspection.
