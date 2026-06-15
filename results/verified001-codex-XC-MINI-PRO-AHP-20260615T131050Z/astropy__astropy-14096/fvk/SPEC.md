# FVK Spec: SkyCoord Subclass Property AttributeError

Status: constructed, not machine-checked. No tests, Python, or K tooling were run.

## Unit Under Audit

Production file:

- `repo/astropy/coordinates/sky_coordinate.py`

Public behavior under audit:

- Normal Python attribute access on a `SkyCoord` instance or subclass instance.
- `SkyCoord.__getattribute__` and `SkyCoord.__getattr__` interaction when a
  custom subclass `@property` raises `AttributeError`.
- Existing `SkyCoord.__getattr__` dynamic behavior for frame aliases, frame
  attributes, delegated frame attributes, transforms, and the generic missing
  attribute error.

## Intent Spec

Intent-only obligations from public evidence:

1. A custom property on a `SkyCoord` subclass is part of the normal public
   Python attribute surface.
2. If that property raises `AttributeError` while trying to access an inner
   missing attribute, the final exception must identify the inner missing
   attribute, not the property name.
3. Existing `SkyCoord` dynamic attribute behavior must continue for attributes
   that are not failing custom subclass properties.
4. The fix should be production-code only; tests are fixed and hidden for this
   benchmark.

## Public Evidence Ledger

| ID | Source | Evidence | Semantic obligation | Status |
|---|---|---|---|---|
| E1 | `benchmark/PROBLEM.md` | "I'm trying to subclass `SkyCoord`, and add some custom properties." | Custom subclass properties are in-domain. | Encoded in PO1, PO4. |
| E2 | `benchmark/PROBLEM.md` | "`prop` below ... tries to access a non-existent attribute (`random_attr`)." | Property getter can raise `AttributeError` from an inner missing attribute. | Encoded in PO1. |
| E3 | `benchmark/PROBLEM.md` | "the error message is misleading because it says `prop` doesn't exist, where it should say `random_attr` doesn't exist." | Final `AttributeError` should preserve the inner missing attribute. | Encoded in PO1. |
| E4 | source comments in `SkyCoord.__getattr__` | "Overrides getattr to return coordinates that this can be transformed to..." | Existing dynamic transform/fallback behavior is intended for non-property cases. | Encoded in PO3. |
| E5 | Python object model default-domain assumption | Normal attribute lookup honors the first class provider in MRO before `__getattr__`. | A custom property must win over `SkyCoord.__getattr__` fallback when it is the first MRO provider. | Encoded in PO4. |
| E6 | FVK audit of V1 | V1 called `descriptor.__get__` inside `__getattr__`. | A failing property could be evaluated twice. | Finding F2; fixed in V2 and PO2. |

The quoted pre-fix traceback in the issue is marked SUSPECT legacy behavior: it
shows the bug symptom, not the desired contract.

## Formal Model

The auxiliary K files model a small Python attribute-access fragment:

- `fvk/mini-python-attr.k`: abstract semantics for normal attribute access,
  subclass property failure, the Python fall-through to `__getattr__`, the V2
  saved-error handoff, and the existing SkyCoord fallback.
- `fvk/skycoord-attribute-access-spec.k`: K-style claims for the obligations
  below.

The model intentionally abstracts away coordinate math and frame transforms. The
observable property is the final attribute-access outcome: a raised
`AttributeError` naming either the inner missing attribute, the property itself,
or the existing SkyCoord fallback path.

## Proof Obligations Summary

Full obligations are listed in `fvk/PROOF_OBLIGATIONS.md`.

- PO1: A subclass property whose getter raises `AttributeError(random_attr)`
  must make `c.prop` raise that same error, not `AttributeError(prop)`.
- PO2: The property getter is invoked once on the failing access path.
- PO3: Attributes that are not subclass properties continue through the existing
  `SkyCoord.__getattr__` dynamic fallback.
- PO4: The custom-property decision follows the first provider in Python MRO and
  excludes providers from `SkyCoord`'s own hierarchy.
- PO5: The saved exception marker is consumed exactly once and cannot pollute an
  unrelated missing attribute lookup.
- PO6: No public method signatures or test files change.

## Domain and Residual Scope

In scope:

- `property` descriptors defined by a subclass, a subclass's custom base class,
  or a mixin appearing anywhere in the instance MRO, provided that the first MRO
  provider for the attribute is outside `SkyCoord.__mro__`.
- `AttributeError` raised by the property getter during normal attribute access.

Out of scope, by public-intent adequacy:

- Arbitrary non-`property` descriptors such as `cached_property`; the issue
  reproducer uses `@property`, and no public evidence requires broader
  descriptor support.
- Changing `SkyCoord`'s own built-in properties.
- Running or modifying tests.

