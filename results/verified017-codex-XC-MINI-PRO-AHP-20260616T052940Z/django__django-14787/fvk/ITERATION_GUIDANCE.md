# FVK Iteration Guidance

Status: constructed, not machine-checked.

## Code Decision

V1 stands unchanged.

Reason: F-001 localizes the reported failure to metadata lookup on the plain
partial passed to decorators. PO-001 and PO-002 show that V1 copies wrapper
assignments onto that partial before decorators run. PO-003 through PO-006 show
that the existing call behavior, decorator order, outer-wrapper attribute
propagation, and public API shape are framed unchanged.

## Recommended Tests to Add or Keep

Do not edit tests in this task. For future human-maintained tests, useful cases
are:

- A decorator using `@wraps(func)` and `func.__name__` with
  `@method_decorator(logger)`.
- Preservation of `__module__`, `__qualname__`, `__doc__`, and `__annotations__`
  on the decorator-facing callable when present on the method.
- Existing decorator-order, descriptor, decorator-added attribute, class
  decoration, and invalid-name/non-callable-attribute tests.

No test should be removed unless the constructed proof is later machine checked
with `kprove` and returns `#Top`.

## Future Verification Work

Run these only in an environment with K installed and where execution is allowed:

```sh
kompile fvk/mini-method-decorator.k --backend haskell
kast --backend haskell fvk/method-decorator-spec.k
kprove fvk/method-decorator-spec.k
```

If a future machine check fails, inspect PO-001 first. A failure there would
mean the abstract semantics does not capture `wraps(method)(partial(...))`
metadata copying precisely enough, or that the proof needs a stronger library
lemma for `functools.update_wrapper()`.

## No Open Repair Items

No additional source edit is recommended. Replacing the partial with a nested
function remains rejected because E-004 requires an attribute-assignable callable
without changing the established binding behavior, and PO-003 is already
discharged by keeping the partial.
