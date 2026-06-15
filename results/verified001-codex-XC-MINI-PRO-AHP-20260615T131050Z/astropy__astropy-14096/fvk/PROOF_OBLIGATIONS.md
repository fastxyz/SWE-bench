# Proof Obligations

Status: constructed, not machine-checked.

## PO1: Preserve the inner AttributeError for custom subclass properties

For every object `c` whose type is a subclass of `SkyCoord`, every attribute
name `prop`, and every error `E = AttributeError(inner)`:

Preconditions:

- The first class in `type(c).__mro__` that defines `prop` is outside
  `SkyCoord.__mro__`.
- That class's descriptor for `prop` is an instance of `property`.
- Normal descriptor evaluation of `prop` raises `E`.

Postcondition:

- Normal access `c.prop` raises `E`.
- The final error is not replaced by `AttributeError(prop)` from the generic
  SkyCoord fallback.

Findings traced:

- F1, F2.

## PO2: Do not replay the failing property

For the PO1 path:

Preconditions:

- `c.prop` performs normal Python attribute access.
- The property getter raises `AttributeError`.

Postcondition:

- The property getter is invoked exactly once during that access.
- `SkyCoord.__getattr__` does not call `descriptor.__get__`.

Findings traced:

- F2.

## PO3: Preserve existing SkyCoord dynamic fallback outside the custom-property path

For every attribute `attr` that is not the PO1 custom-property case:

Preconditions:

- No saved property error marker for `attr` exists.
- The original V1/V2 helper either finds no first MRO provider for `attr`, finds
  a non-`property` provider, or finds a provider inside `SkyCoord.__mro__`.

Postcondition:

- `SkyCoord.__getattr__` follows the existing order:
  1. current frame name returns `self`;
  2. frame attributes delegate to `self.frame` or private `self._<attr>`;
  3. public attributes available on `self._sky_coord_frame` delegate there;
  4. transformable frame aliases return `self.transform_to(attr)`;
  5. otherwise raise the generic missing-attribute `AttributeError(attr)`.

Findings traced:

- F1, F4.

## PO4: Respect Python MRO and exclude SkyCoord-owned properties

For every attribute `attr` and object `c`:

Preconditions:

- `type(c).__mro__` is finite.
- The helper searches for the first class in that MRO whose `__dict__` contains
  `attr`.

Postcondition:

- If the first provider is outside `SkyCoord.__mro__` and its descriptor is a
  `property`, V2 treats it as a custom subclass property.
- If the first provider is in `SkyCoord.__mro__`, V2 does not intercept it.
- If the first provider is not a `property`, V2 does not intercept it.
- If no provider exists, V2 does not intercept it.

Findings traced:

- F3, F4.

## PO5: Saved-error marker is single-use and attribute-matched

Preconditions:

- `__getattribute__` saved marker `(prop, E)` after a PO1 property failure.
- Python then calls `__getattr__(attr)`.

Postcondition:

- `__getattr__` removes the marker before continuing.
- If `attr == prop`, `__getattr__` raises `E`.
- If `attr != prop`, the marker is discarded and normal SkyCoord fallback
  continues for `attr`.
- No stale marker remains in `self.__dict__` after the `__getattr__` call.

Findings traced:

- F2.

## PO6: Public compatibility and mutation boundary

Preconditions:

- Existing public callers use `SkyCoord` attribute access, `__getattr__`,
  frame aliases, frame attributes, and transformations.

Postcondition:

- No public method signature changes.
- No test files are modified.
- New implementation details are private to `SkyCoord`.
- Non-property dynamic attributes continue to use the previous fallback body.

Findings traced:

- F4, F5.

