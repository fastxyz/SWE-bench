# FVK Proof

Status: constructed, not machine-checked. No tests, Python, `kompile`, `kast`,
or `kprove` commands were executed.

## What Is Proved

For every in-domain use of `method_decorator()` where the original method has
standard function wrapper metadata, the callable passed to user decorators by
`_multi_decorate()` preserves that metadata before the decorators run. In
particular, if the original method has `__name__`, a decorator that reads
`func.__name__` from its received callable does not fail merely because the
callable is a `functools.partial`.

The proof is partial correctness: if decorator and method execution return, the
metadata and call-behavior postconditions hold. Termination of arbitrary user
decorators is outside the scope.

## Constructed Proof

1. Pre-fix failure localization.

   In V0, `_multi_decorate()` constructed:

   ```python
   bound_method = partial(method.__get__(self, type(self)))
   ```

   The public issue's `logger` receives this partial as `func`. The partial is
   callable, but it is not initialized with normal function metadata. The
   `finally` block reads `func.__name__`, so the modeled lookup reaches an
   undefined metadata key and raises `AttributeError`. This proves F-001 is
   localized to the callable supplied to decorators, not to the outer method
   wrapper after decoration.

2. V1 metadata step.

   V1 constructs:

   ```python
   bound_method = wraps(method)(partial(method.__get__(self, type(self))))
   ```

   By the semantics of `functools.wraps`, this applies
   `update_wrapper(partial(...), method)`. For each standard wrapper assignment
   present on `method`, `update_wrapper()` sets the same attribute on the
   partial. It also updates the partial's `__dict__` from the method and sets
   `__wrapped__`.

   This discharges PO-001.

3. Issue example.

   Instantiate PO-001 with a method whose `__name__` is `hello_world`. Before
   `logger` is applied, the partial has `__name__ == "hello_world"`. Therefore
   the lookup in `logger` is defined and equals the original method name.

   This discharges PO-002 and resolves F-001.

4. Call behavior frame.

   `wraps(method)` mutates metadata on the partial object. It does not replace
   the partial's target callable, stored positional arguments, stored keyword
   arguments, or the bound method returned by `method.__get__(self, type(self))`.
   Therefore the call step remains equivalent to calling the original bound
   method with the same `*args` and `**kwargs`.

   This discharges PO-003.

5. Decorator-order frame.

   V1 does not change:

   ```python
   if hasattr(decorators, '__iter__'):
       decorators = decorators[::-1]
   else:
       decorators = [decorators]

   for dec in decorators:
       bound_method = dec(bound_method)
   ```

   The normal decorator order already required by public tests is framed
   unchanged. This discharges PO-004.

6. Outer wrapper frame.

   V1 does not change the two outer-wrapper propagation steps:

   ```python
   for dec in decorators:
       _update_method_wrapper(_wrapper, dec)
   update_wrapper(_wrapper, method)
   ```

   Existing behavior that copies decorator-added attributes and method metadata
   to `Test.method` and `Test().method` is preserved. This discharges PO-005.

7. Compatibility.

   The source diff is limited to one expression inside `_wrapper`. It does not
   alter `method_decorator()`'s signature, class-decoration validation,
   non-callable error branch, missing-name error branch, or return shape. The
   only new observable is stronger metadata on the decorator input, which is the
   public intent. This discharges PO-006.

## Adequacy Result

The formal English claims C-001 through C-005 in `fvk/SPEC.md` match the
intent-only obligations I-001 through I-005. No claim preserves the legacy
metadata-empty partial; that behavior is marked suspect by E-002 and F-001.

## Test Guidance

No tests were run and no test files were edited.

Tests that check the issue example and standard wrapper assignments would be
subsumed by PO-001 and PO-002 only after a real `kprove` run returns `#Top`.
Until then, keep them. Existing decorator-order, descriptor, and attribute tests
remain useful integration coverage for behavior framed by PO-003 through PO-005.

## Machine-Check Commands

These commands were not executed:

```sh
kompile fvk/mini-method-decorator.k --backend haskell
kast --backend haskell fvk/method-decorator-spec.k
kprove fvk/method-decorator-spec.k
```

Expected machine-check result in a suitable environment: `#Top`.

## Residual Risk

The proof uses an abstract mini semantics for Python callable metadata flow, not
a full Python semantics. It relies on the standard behavior of
`functools.wraps()` / `functools.update_wrapper()` and on partial objects being
attribute-assignable. These are public Python library semantics, but they were
not executed in this benchmark environment.

No unresolved code bug remains within the audited intent. V1 stands unchanged.
