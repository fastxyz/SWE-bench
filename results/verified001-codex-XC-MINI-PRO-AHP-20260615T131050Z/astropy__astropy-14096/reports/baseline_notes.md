# Baseline Notes

## Root cause

`SkyCoord` implements `__getattr__` to provide dynamic access to frame aliases,
frame attributes, and attributes delegated to the underlying coordinate frame.
When a subclass defines a `@property`, Python evaluates that descriptor during
normal attribute lookup before calling `__getattr__`. If the property body raises
`AttributeError`, Python treats the descriptor lookup as failed and then calls
`SkyCoord.__getattr__` for the original property name.

The existing fallback in `SkyCoord.__getattr__` did not distinguish this case
from a genuinely missing attribute, so it raised an error saying that the
subclass instance had no attribute with the property name. That hid the actual
missing attribute referenced inside the property.

## Files changed

`repo/astropy/coordinates/sky_coordinate.py`

Added a small check at the start of `SkyCoord.__getattr__` for properties
defined on subclasses of `SkyCoord`. If the requested attribute is such a
property, `__getattr__` invokes the property's descriptor directly. This lets an
`AttributeError` raised inside the property body propagate with its original
message, such as the missing inner attribute name, instead of being replaced by
the generic SkyCoord fallback message for the property name.

## Assumptions and alternatives considered

I assumed the intended behavior is to preserve the useful `AttributeError`
message for custom `SkyCoord` subclass properties while leaving SkyCoord's
dynamic frame alias and frame-attribute behavior unchanged.

I considered changing the final generic `AttributeError` message in
`SkyCoord.__getattr__`, but that would still not identify which attribute inside
the property body was missing.

I considered modifying `SkyCoord.__getattribute__`, but Python still routes
`AttributeError` from normal descriptor lookup to `__getattr__`, so a
`__getattr__`-level fix is the narrower change.

I limited the descriptor re-entry to `property` objects found before `SkyCoord`
in the method-resolution order. This targets subclass-defined custom properties
without changing the behavior of SkyCoord's own built-in properties or unrelated
dynamic attributes.
