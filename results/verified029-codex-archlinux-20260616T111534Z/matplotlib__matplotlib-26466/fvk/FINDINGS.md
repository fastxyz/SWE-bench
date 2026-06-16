# Findings

Status: constructed, not machine-checked. No tests, Python code, or K tooling
were run.

## F1: Original mutable-`xy` aliasing bug

Input:

```python
xy_0 = np.array((-4, 1))
ax.annotate(s='', xy=xy_0, xytext=np.array((-1, 1)),
            arrowprops=dict(arrowstyle='<->'))
xy_0[1] = 3
```

Observed before the fix: the first arrow endpoint was recomputed from the
mutated array and moved from y=1 to y=3.

Expected: the annotation stores the construction-time point `(-4, 1)`, so the
arrow remains horizontal.

Status: closed by PO1. `_AnnotationBase.__init__` now stores `tuple(xy)`.

## F2: Similar delayed-use coordinate storage in `OffsetFrom`

Input shape: `OffsetFrom(artist, ref_coord=np.array((x, y)))`, followed by a
mutation of that array before drawing.

Observed risk in V0: `_ref_coord` retained the caller object and was read later
in `__call__`.

Expected: `OffsetFrom` computes from the construction-time reference coordinate.

Status: closed by PO2. `OffsetFrom.__init__` now stores `tuple(ref_coord)`.

## F3: `AnnotationBbox.xybox` default needed the copied `xy`

Input shape: `AnnotationBbox(offsetbox, xy=np.array((x, y)))` with omitted
`xybox`, followed by mutation of `xy`.

Observed risk in V1 audit target if left unchanged: even after `_AnnotationBase`
copied `xy`, assigning `xybox` from the original `xy` parameter would reintroduce
an alias on the default box-position path.

Expected: omitted `xybox` defaults to copied `self.xy`.

Status: closed by PO3. V1 uses `self.xy` for the default.

## F4: NumPy-array storage would repair aliasing but break tuple-style behavior

Input shape: public code or tests that compare `ann.xy == (x, y)`.

Observed risk: a universal `np.array(xy)` storage change would make equality
array-valued and could raise ambiguous truth-value errors in boolean contexts.

Expected: coordinates remain tuple-like while still detached from caller arrays.

Status: closed by PO5. V1 uses `tuple(...)`.

## F5: Shallow-copy boundary for non-scalar coordinate elements

Input shape: `xy` contains mutable objects as coordinate elements, for example a
list of two mutable containers.

Observed: `tuple(xy)` is a shallow copy of the two elements.

Expected under the public contract: coordinate elements are scalar coordinate
values, documented as `(float, float)` or unit-convertible scalar values.

Status: not a code bug for this issue. The scalar-coordinate precondition is
explicit in `SPEC.md`. If Matplotlib later documents nested mutable coordinate
objects as valid scalar coordinates, this should be reopened.

## F6: V1 `ConnectionPatch` change is compatible but not required by the issue

Input shape: `ConnectionPatch(xyA=np.array((x1, y1)), xyB=np.array((x2, y2)), ...)`
followed by mutations to the endpoint arrays.

Observed risk in the old code: endpoint attributes retained caller arrays and
were read later.

Expected under public stubs: `xy1` and `xy2` are coordinate tuples.

Status: accepted by PO4 and the compatibility audit. It is broader than the
specific `Axes.annotate` reproduction but follows the same delayed-use storage
pattern without changing signatures or documented types.

## Proof-Derived Findings from `/verify`

No additional production-code defect was found in V1 for the stated
coordinate-storage contract. The proof is partial and constructed only; it does
not prove rendering geometry, transform correctness, or termination. Test
removal is not recommended without running the emitted K commands and the
project test suite in a real environment.
