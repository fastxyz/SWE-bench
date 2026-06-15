# Constructed Proof

Status: constructed, not machine-checked. No tests, Python, `kompile`, or
`kprove` were run.

## K Artifacts and Commands

Auxiliary formal files:

- `fvk/mini-python-attr.k`
- `fvk/skycoord-attribute-access-spec.k`

Commands to run later in an environment with K installed:

```sh
kompile fvk/mini-python-attr.k --backend haskell
kast --backend haskell fvk/skycoord-attribute-access-spec.k
kprove fvk/skycoord-attribute-access-spec.k
```

Expected machine-check result: `#Top` for all claims. This expectation is not
asserted as machine-checked here because the commands were not run.

## Adequacy Gate

The English intent requires the final exception for the reproducer to name
`random_attr`, not `prop`. PO1 states exactly that. PO2 is added by FVK audit
because V1 achieved PO1 by running the property a second time; replay is not
required by public intent and is avoidable. PO3 and PO6 prevent the proof from
overfitting the issue path by preserving existing non-property SkyCoord dynamic
attribute behavior. PO4 encodes Python's default MRO convention so custom
property providers are not missed outside the direct subclass body.

## Proof Sketch for PO1

Initial state:

- `c` is a `SkyCoord` subclass instance.
- The first MRO provider for `prop` is a custom class outside
  `SkyCoord.__mro__`.
- The provider's descriptor is a `property`.
- Evaluating the property raises `E = AttributeError(random_attr)`.

Symbolic execution:

1. Normal access `c.prop` enters `SkyCoord.__getattribute__("prop")`.
2. `super().__getattribute__("prop")` follows Python descriptor lookup and
   invokes the property getter.
3. The getter raises `E`.
4. The `except AttributeError as exc` branch in `__getattribute__` executes with
   `exc = E`.
5. `_get_subclass_property_descriptor("prop")` scans the MRO and returns the
   property descriptor because the first provider is outside `SkyCoord.__mro__`.
6. `__getattribute__` stores marker `(prop, E)` on the instance and re-raises.
7. Python's attribute lookup protocol calls `SkyCoord.__getattr__("prop")`.
8. `__getattr__` pops marker `(prop, E)`, sees that the marker attribute equals
   the requested attribute, and raises `E`.

Postcondition:

- The final exception is the same `AttributeError` raised by the property getter
  path, so its message names `random_attr`. The generic SkyCoord
  `AttributeError(prop)` is not reached.

## Proof Sketch for PO2

The only descriptor invocation on the PO1 path is step 2 above:
`super().__getattribute__("prop")` invokes the property getter. After that,
`__getattr__` either raises the saved exception or continues to the existing
fallback body. V2 contains no `descriptor.__get__` call in `__getattr__`.
Therefore the failing property is not replayed.

This discharges Finding F2.

## Proof Sketch for PO3

For any attribute outside the PO1 custom-property case, one of these holds:

- no saved marker exists;
- a saved marker exists for a different attribute and is discarded;
- the first MRO provider is in `SkyCoord.__mro__`;
- the first MRO provider is not a `property`;
- there is no MRO provider.

In each case `__getattr__` reaches the original fallback body. That body is
unchanged from the legacy implementation: frame-name check, frame-attribute
handling, delegation to `_sky_coord_frame`, transform alias lookup, then generic
missing-attribute error. Thus the patch is framed to the custom-property failure
path and does not alter the intended dynamic coordinate behavior.

## Proof Sketch for PO4

`_get_subclass_property_descriptor` iterates over `type(self).__mro__`, which is
finite by Python's class model. The first class whose `__dict__` contains the
attribute determines the provider. The helper returns a descriptor only when
that provider is outside `SkyCoord.__mro__` and the descriptor is a `property`.
It breaks on the first provider in all cases, matching Python's MRO precedence
for this audit's property-detection purpose.

Therefore:

- a direct subclass property is covered;
- a custom base or mixin property is covered when it is the first provider;
- a `SkyCoord` built-in property is not intercepted;
- a later provider cannot override an earlier provider for this decision.

This discharges Finding F3.

## Proof Sketch for PO5

`__getattr__` obtains the marker with `pop`, not `get`, so after the first
`__getattr__` call no marker remains. If the requested attribute matches the
marker attribute, the saved exception is raised immediately. If it does not
match, the marker is already removed and the method continues through normal
fallback. Therefore no stale marker can affect later attribute lookups.

## Public Compatibility

No public method signature changed. The new helper and marker name are private
implementation details. Test files were not modified. The proof intentionally
does not recommend deleting tests, because the proof is constructed only and
the benchmark forbids running the test suite.

## Residual Risk

- The formal core is a mini-Python abstraction, not full Python semantics.
- The proof is partial correctness only; termination is evident from finite MRO
  traversal but not machine-checked.
- Arbitrary non-`property` descriptors remain outside the verified domain.
- Machine checking with K was not run.
