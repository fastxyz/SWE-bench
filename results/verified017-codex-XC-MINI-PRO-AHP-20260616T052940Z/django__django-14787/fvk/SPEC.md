# FVK Spec: `method_decorator()` Wrapper Assignments

Status: constructed, not machine-checked. No tests, Python, or K commands were
executed.

## Scope

Audited unit:

- `repo/django/utils/decorators.py::_multi_decorate()`
- `repo/django/utils/decorators.py::method_decorator()` as the public entry point

The model focuses on the observable issue: the callable passed to each user
decorator must behave like the bound method for calls and must expose the
standard wrapper-assignment metadata that exists on the original method. The
model abstracts arbitrary decorator bodies into transformers that may inspect
metadata, attach attributes, and call the wrapped callable.

## Intent Spec

I-001. `method_decorator()` converts a function decorator into a method
decorator.

I-002. The callable passed to a function decorator by `method_decorator()` must
not be a metadata-empty `functools.partial` when the original method has normal
function metadata.

I-003. Standard wrapper assignments are in scope: `__module__`, `__name__`,
`__qualname__`, `__doc__`, and `__annotations__`. Copying the wrapped
callable's `__dict__` and setting `__wrapped__` are acceptable because they are
part of `functools.update_wrapper()` behavior used by `functools.wraps()`.

I-004. A decorator like the issue's `logger`, which uses `@wraps(func)` and
later reads `func.__name__`, must not raise `AttributeError` merely because
`method_decorator()` supplied a partial object.

I-005. Existing method-decorator behavior must be preserved: the synthetic
callable still omits `self` from the decorator-facing signature, still calls the
original bound method, still lets decorators attach attributes, and still applies
iterable decorators in normal decorator order.

## Public Evidence Ledger

E-001, prompt, encoded: "method_decorator() should preserve wrapper assignments"
-> postcondition that wrapper-assignment metadata visible on `method` is also
visible on the callable passed to each decorator.

E-002, prompt, encoded: "the function that is passed to the decorator is a
partial object and does not have any of the attributes expected from a function
i.e. __name__, __module__ etc" -> observed pre-fix behavior is suspect and must
not be preserved.

E-003, prompt example, encoded: `logger` reads `func.__name__` in `finally` ->
for a method named `hello_world`, the decorator-facing callable must define
`__name__ == "hello_world"` before `logger` is applied.

E-004, source comment, encoded: `_multi_decorate()` uses a bound-method partial
so decorators see no `self` argument and can set attributes on a function-like
object -> the fix must keep a mutable callable wrapper rather than pass a raw
bound method object.

E-005, public tests in `repo/tests/decorators/tests.py`, encoded: preserve
decorator-added attributes, method `__doc__`, method `__name__`, descriptor
wrapping, class decoration, and iterable decorator order -> the fix must not
change decorator order or outer wrapper metadata propagation.

E-006, implementation, encoded: V1 constructs
`wraps(method)(partial(method.__get__(self, type(self))))` before applying
decorators -> candidate mechanism for satisfying E-001 through E-004.

## Formal Model

The mini semantics has these abstract state components:

- `method`: a callable descriptor with call behavior `method(self, args)`.
- `meta(method)`: a finite metadata map.
- `assigned`: the standard wrapper-assignment key set from I-003.
- `partial(bound(method, self))`: a callable that invokes the bound method and
  can receive attributes.
- `copy_assigned(target, method)`: `functools.update_wrapper()` restricted to
  wrapper-assignment metadata plus the standard wrapper dictionary update.
- `decorator(callable)`: an abstract transformer that may inspect metadata,
  attach attributes, return a wrapper, and/or call the callable.

Domain assumptions:

- `method` is callable through `method.__get__(self, type(self))`.
- The obligation copies metadata that exists on `method`; it does not invent
  absent metadata.
- `decorators` is either a single decorator or a finite sliceable iterable, as
  required by the existing implementation.
- Partial correctness only: if decorator or method execution returns, the
  specified metadata and call-behavior properties hold.

## K-Style Claims

The formal core is written as abstract K-style reachability claims in
`fvk/PROOF_OBLIGATIONS.md`. The intended machine-check commands, not executed
in this environment, are:

```sh
kompile fvk/mini-method-decorator.k --backend haskell
kast --backend haskell fvk/method-decorator-spec.k
kprove fvk/method-decorator-spec.k
```

Expected outcome after a real machine check: `#Top` for the claims listed in
`fvk/PROOF_OBLIGATIONS.md`.

## Formal Spec English

C-001. Building the decorator-facing bound callable from a method first creates
a partial over the bound method and then copies each present standard wrapper
assignment from the original method onto that partial.

C-002. If `method.__name__` exists, then any decorator that receives the
decorator-facing callable can read `func.__name__` and obtains the same value.

C-003. Copying metadata onto the partial does not change the partial's call
target: calling it is still equivalent to calling `method.__get__(self,
type(self))(*args, **kwargs)`.

C-004. Multiple decorators are applied in the same order as before V1: iterable
decorators are reversed once and then applied left to right in the loop.

C-005. Attributes added by decorators to the outer method wrapper and existing
method metadata on that outer wrapper are still handled by the pre-existing
`_update_method_wrapper()` and final `update_wrapper(_wrapper, method)` calls.

## Adequacy Audit

C-001 passes I-001 through I-003 and is directly supported by E-001, E-002, and
E-006.

C-002 passes I-004 and is directly supported by E-003.

C-003 passes I-005 and is supported by E-004 because the fix retains the partial
over `method.__get__()`.

C-004 passes I-005 and is supported by E-005 because the fix does not modify the
decorator-list normalization or application loop.

C-005 passes I-005 and is supported by E-005 because the fix does not modify the
outer-wrapper attribute-copying code.

No formal-English claim is derived solely from current V1 behavior. The current
implementation appears only as implementation evidence for how E-001 is
discharged.

## Public Compatibility Audit

Changed public surface: none. The signature and return shape of
`method_decorator()` and `_multi_decorate()` are unchanged.

Changed internal observable: the callable passed to user decorators now exposes
more metadata when the original method has it. This is the intended public
behavior from E-001 and E-002.

Public callsites searched in `repo/django` and `repo/tests`: admin/auth/view
decorator uses, generic view uses, middleware uses, and decorator tests. They
depend on call behavior, decorator order, and attribute propagation. Those
properties are preserved by C-003 through C-005.

Compatibility conclusion: no additional production code change is justified.
