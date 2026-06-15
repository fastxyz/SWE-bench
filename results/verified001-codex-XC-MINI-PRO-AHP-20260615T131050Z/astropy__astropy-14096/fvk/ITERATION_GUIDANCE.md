# Iteration Guidance

Status: constructed, not machine-checked.

## V2 Code Guidance Applied

The FVK audit justified replacing V1's descriptor replay with a saved-exception
handoff:

- Finding F2 showed that V1 could execute a failing property twice.
- PO2 required exactly one property getter invocation on the failing access path.
- PO5 required single-use cleanup of the saved exception marker.

The audit also justified broadening the MRO scan:

- Finding F3 showed that stopping at `SkyCoord` could miss custom property
  providers elsewhere in the MRO.
- PO4 required using the first MRO provider while excluding `SkyCoord`'s own
  hierarchy.

## Recommended Tests for Maintainers

Do not add or modify tests in this benchmark. In a normal development setting,
the following tests would be appropriate:

- A direct subclass property `prop` that returns `self.random_attr` raises an
  `AttributeError` whose message names `random_attr`.
- A failing property with a counter increments the counter once, not twice.
- A custom property from a user-defined mixin/base class is handled when it is
  the first MRO provider outside `SkyCoord.__mro__`.
- A built-in SkyCoord dynamic alias such as a transformable frame name still
  follows the existing transform path.
- A genuinely missing non-property attribute still raises the generic
  SkyCoord missing-attribute message for that attribute.

## No-Change Decisions

- Non-`property` descriptors were not added to the verified domain. This follows
  Finding F4: the public issue uses `@property`, and broad descriptor support
  lacks public intent evidence.
- Existing `SkyCoord.__getattr__` frame and transform fallback ordering was left
  unchanged. This follows PO3 and PO6.
- No tests were edited or run. This follows the benchmark constraints and F5.

## Future Formal Work

Run the emitted commands when K tooling is available:

```sh
kompile fvk/mini-python-attr.k --backend haskell
kast --backend haskell fvk/skycoord-attribute-access-spec.k
kprove fvk/skycoord-attribute-access-spec.k
```

If public intent later requires arbitrary descriptors, extend
`_get_subclass_property_descriptor` into a descriptor classifier and add a new
claim covering non-`property` descriptor failure.

