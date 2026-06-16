# Formal Spec English

Status: paraphrase of `fvk/repeated-splits-repr-spec.k`; constructed, not
machine-checked.

C1. Calling the repeated-splitter repr operation on a repeated splitter object
performs exactly one delegation step to the shared build-repr operation.

C2. For a default `RepeatedKFold` object whose direct attributes contain
`n_repeats=10` and `random_state=None`, and whose `cvargs` contain
`n_splits=5`, the repr result is
`RepeatedKFold(n_repeats=10, n_splits=5, random_state=None)`.

C3. For a default `RepeatedStratifiedKFold` object with the same parameter
storage shape, the repr result is
`RepeatedStratifiedKFold(n_repeats=10, n_splits=5, random_state=None)`.

C4. When a direct attribute and a `cvargs` entry both exist for the same key, the
direct attribute value is used. This preserves existing direct-attribute
behavior and prevents `cvargs` from overriding public attributes.

C5. When neither a direct attribute nor a `cvargs` entry exists for a constructor
parameter, the representation value for that parameter is `None`, matching the
old helper behavior for missing attributes.

C6. The parameter order in the claims is the established `_build_repr`/`_pprint`
sorted-key order used by existing cross-validation splitters.

