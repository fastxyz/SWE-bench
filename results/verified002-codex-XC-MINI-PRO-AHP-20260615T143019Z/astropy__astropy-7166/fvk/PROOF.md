# FVK Proof

Status: constructed, not machine-checked. No tests, Python execution, `kompile`,
`kast`, or `kprove` were run.

## Artifacts

- Mini semantics: `fvk/mini-python-inherit-docstrings.k`
- Claims: `fvk/inherit-docstrings-spec.k`
- Exact commands to machine-check later:

```sh
kompile fvk/mini-python-inherit-docstrings.k --backend haskell
kast --backend haskell fvk/inherit-docstrings-spec.k
kprove fvk/inherit-docstrings-spec.k
```

Expected machine-check result: all claims discharge to `#Top`.

## Constructed Proof Summary

For each class namespace member, `InheritDocstrings.__init__` evaluates three
guards before it mutates anything:

1. `is_inheritable_member(val)` is true only for functions or data descriptors.
2. `is_public_member(key)` matches the pre-existing public/dunder rule.
3. `val.__doc__ is None` means the subclass member did not provide an explicit
   docstring.

If any guard fails, the member is framed unchanged. This proves PO-05.

If all guards hold, the code scans `cls.__mro__[1:]`. The first base whose
member lookup produces a non-`None` value supplies the copied docstring and the
loop breaks. This proves PO-04.

For function members, the lookup remains `getattr(base, key, None)`, the same
lookup used before V1. This preserves method behavior and proves PO-02.

For data-descriptor members, lookup is `inspect.getattr_static(base, key, None)`.
That gives the raw inherited descriptor object rather than invoking `__get__`.
For a normal property or property subclass with writable `__doc__`, assigning
`val.__doc__ = super_method.__doc__` yields the inherited docstring. This proves
PO-01 and PO-03 for the reported property case.

For a data descriptor with read-only `__doc__`, assignment raises
`AttributeError` or `TypeError`; V2 catches those exceptions and leaves the
descriptor unchanged. This discharges PO-07 and removes F-01.

The final `super().__init__(name, bases, dct)` remains in place, proving PO-08.
The loops range over finite `dct.items()` and finite `cls.__mro__`, proving
PO-09 as a simple termination argument for this metaclass pass.

## Adequacy Gate

The formal-English claims in `fvk/SPEC.md` match the public-intent ledger:

- Property inheritance is directly required by E1-E3.
- Function behavior preservation is required by E4.
- First-MRO precedence is required by E5.
- Explicit-doc preservation is required by E6.
- Public API compatibility is required by E7.
- Read-only descriptor handling is justified by F-01/E8 as a V1 regression risk
  created by broadening the eligible member family.

No proof obligation preserves the old bug where properties were skipped.

## Test Redundancy Recommendation

No test removal is recommended. The proof is constructed only, and the user
forbids modifying tests. Existing method-doc tests should be kept until a real
machine check returns `#Top`; additional property-focused tests would still be
useful because the in-repo visible coverage did not exercise the reported
property case.

## Residual Risk

The mini semantics abstracts Python's full descriptor and metaclass machinery.
It is adequate for the audited observable, but it is not a substitute for
machine-checking against a full Python semantics. The proof is partial with
respect to this abstraction and constructed only.
