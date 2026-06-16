# FVK Findings

Status: constructed, not machine-checked. No tests, Python, or K commands were
executed.

## Formalize Findings

F-001, code bug resolved by V1.

Input: a method decorated with `@method_decorator(logger)` where `logger`
captures `func` and later reads `func.__name__`.

Observed before V1: `_multi_decorate()` passed a plain
`functools.partial(method.__get__(self, type(self)))` to `logger`; that partial
did not define `__name__`, so `logger` could raise `AttributeError:
'functools.partial' object has no attribute '__name__'`.

Expected: the decorator-facing callable preserves wrapper assignments from the
original method, so `func.__name__` is defined when the method has `__name__`.

Resolution: V1 applies `wraps(method)` to the partial before any decorator sees
it. This discharges PO-001 and PO-002.

F-002, candidate adequacy confirmed.

Input class: decorators that inspect standard wrapper-assignment metadata on the
callable supplied by `method_decorator()`.

Observed in V1: the partial is still used, but it is first passed through
`functools.wraps(method)`, which copies standard wrapper assignments from
`method` onto the partial.

Expected: the callable passed to decorators has the method metadata required by
the issue.

Resolution: no source change beyond V1 is justified. This is covered by PO-001.

F-003, call behavior and decorator order preserved.

Input class: existing method-decorator uses that rely on omitted `self`,
decorator stacking order, decorator-added attributes, descriptor wrappers, or
class decoration.

Observed in V1: the patch does not change decorator normalization, decorator
application order, the final call to `bound_method(*args, **kwargs)`, or the
outer `_update_method_wrapper()` / `update_wrapper(_wrapper, method)` logic.

Expected: these existing behaviors remain unchanged while metadata improves.

Resolution: no additional source change is justified. This is covered by PO-003
through PO-006.

F-004, boundary condition accepted.

Input class: a callable method object that genuinely lacks a standard wrapper
assignment.

Observed in V1: `functools.update_wrapper()` semantics copy attributes that
exist and skip missing assigned attributes.

Expected: `method_decorator()` should preserve wrapper assignments, not invent
attributes absent from the original callable.

Resolution: accepted as an out-of-obligation boundary. This is covered by
PO-001's domain clause.

## Proof-Derived Findings from `/verify`

F-005, proof honesty and residual risk.

The proof obligations can be constructed cleanly with a metadata-flow model, but
they have not been machine checked. The model is an abstraction of Python
callable/descriptor/partial behavior rather than a full Python-in-K semantics.

Expected next action before deleting or weakening tests: run the emitted
`kompile`, `kast`, and `kprove` commands in an environment that has K installed.

Resolution: keep tests; do not claim machine-checked proof. This is covered by
PO-007.

F-006, no open code bug found by the FVK audit.

The symbolic pre-fix failure localizes to metadata lookup on the plain partial.
The V1 fix places metadata copying before the first user decorator call, which
is exactly the branch that produces the issue symptom. No sibling branch or
public callsite was found that still passes a metadata-empty partial to a user
decorator within the audited unit.

Resolution: V1 stands unchanged. This follows from PO-001, PO-002, and PO-006.
