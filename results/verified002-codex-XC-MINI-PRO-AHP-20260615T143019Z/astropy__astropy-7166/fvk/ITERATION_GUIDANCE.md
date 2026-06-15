# FVK Iteration Guidance

Status: V2 source change applied.

## Code Decision

Keep V1's core behavior: data descriptors are eligible for inherited docstrings,
and descriptor parents are looked up statically. This is justified by F-02 and
proof obligations PO-01 through PO-06.

Apply one V2 guard: catch `AttributeError` and `TypeError` around `__doc__`
assignment. This is justified by F-01 and PO-07.

## Suggested Future Tests

Do not edit tests in this task. If tests are added later, cover:

- A subclass `@property` with no doc inherits the base property's docstring.
- A subclass property with an explicit docstring keeps its own docstring.
- Multiple inheritance uses the first MRO match.
- A property-like descriptor with custom `__get__` is not invoked during
  inherited-doc lookup.
- A data descriptor with read-only `__doc__` does not abort class creation.
- Existing method inheritance behavior still works.

## Machine Check Later

The constructed proof should be machine-checked before using it to remove tests:

```sh
kompile fvk/mini-python-inherit-docstrings.k --backend haskell
kast --backend haskell fvk/inherit-docstrings-spec.k
kprove fvk/inherit-docstrings-spec.k
```

Until that returns `#Top`, keep all relevant tests.
