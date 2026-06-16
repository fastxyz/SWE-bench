# Iteration Guidance

## Decision

V1 stands unchanged. The FVK audit found that the two V1 changes are exactly the
changes required by the intent-derived proof obligations:

- copy Python context onto field xrefs;
- restrict `refspecific` to leading-dot field targets.

## Do not change

- Do not alter `PythonDomain.find_obj()` globally for this issue. O3-O5 prove
  the intended behavior by feeding existing resolver semantics the right
  metadata.
- Do not preserve legacy tests that require missing `py:module` / `py:class` on
  field-generated Python xrefs. F2 classifies those expectations as SUSPECT.
- Do not remove leading-dot `refspecific` behavior. O6 and F4 preserve it.

## Suggested future tests

Add tests for:

- the issue reproduction's `mod` and `mod.submod` unqualified field type `A`;
- the exact `mod.submod.A` target for `:param A a:` and `:rtype: A`;
- non-module-scope plain `A` with only module-qualified suffix matches;
- `.A` field target behavior to ensure fuzzy lookup is still opt-in.

## Machine-checking

Before using the FVK proof for test-removal decisions, run:

```sh
kompile fvk/mini-sphinx-xref.k --backend haskell
kast --backend haskell fvk/sphinx-xref-spec.k
kprove fvk/sphinx-xref-spec.k
```

This session did not run those commands.
