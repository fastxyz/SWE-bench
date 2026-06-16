# FVK Proof Obligations

Status: constructed, not machine-checked.

## PO-001: Bound manager signature follows the original queryset signature

For every eligible queryset function `method` with parameter list
`(self, p1, ..., pn)`, `inspect.signature()` on the copied bound manager method
returns `(p1, ..., pn)`.

- Intent links: I-001, I-002, I-007.
- Finding links: F-001, F-002.
- Discharge status: satisfied by V1 because `@wraps(method)` supplies
  `__wrapped__ = method`, and bound-method introspection removes the leading
  receiver parameter.

## PO-002: Complete wrapper metadata is preserved

The generated manager proxy preserves the original method metadata copied by
`functools.wraps()`, including `__name__`, `__doc__`, `__module__`,
`__qualname__`, `__annotations__`, wrapper `__dict__`, and `__wrapped__`.

- Intent links: I-003, I-004.
- Finding links: F-001, F-004.
- Discharge status: satisfied by V1 through the `@wraps(method)` decorator.

## PO-003: Pre-fix failure is localized to missing wrapper metadata

The abstract pre-fix proxy had only the generic runtime signature
`(self, *args, **kwargs)` and no `__wrapped__` metadata, so bound introspection
could only expose `(*args, **kwargs)`.

- Intent links: I-001, I-002.
- Finding links: F-001.
- Discharge status: discharged by source comparison between the manual metadata
  assignments in the issue description and the V1 `wraps()` decorator.

## PO-004: Signature behavior is generic over queryset methods

The proof must not depend on the historical `bulk_create()` parameter list shown
in the issue. It must hold for every copied queryset method's current signature.

- Intent links: I-001, I-007.
- Finding links: F-002.
- Discharge status: satisfied because `wraps()` points at the actual function
  object being copied.

## PO-005: Method eligibility filtering is unchanged

For every member returned by `inspect.getmembers(queryset_class,
predicate=inspect.isfunction)`, V1 copies the same methods as before:
skip names already present on the manager, skip `queryset_only=True`, skip
private names when `queryset_only is None`, and copy public or explicitly
`queryset_only=False` methods.

- Intent links: I-005.
- Finding links: F-003.
- Discharge status: satisfied because V1 did not edit the loop conditions or
  dictionary keys.

## PO-006: Runtime forwarding behavior is unchanged

For every copied method name `name`, calling the manager proxy still evaluates
`getattr(self.get_queryset(), name)(*args, **kwargs)`.

- Intent links: I-006.
- Finding links: F-003, F-004.
- Discharge status: satisfied because V1 did not edit the function body of
  `manager_method()`.

## PO-007: Honesty gate for non-executed formal tooling

The FVK package must label claims as constructed, not machine-checked, and must
not recommend deleting tests without a future successful `kprove` result.

- Intent links: FVK `verify.md` honesty gate.
- Finding links: F-005.
- Discharge status: satisfied by artifact labels and by recording commands
  without executing them.
