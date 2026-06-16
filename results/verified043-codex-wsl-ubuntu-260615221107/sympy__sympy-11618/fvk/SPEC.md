# FVK SPEC - sympy__sympy-11618

Status: constructed, not machine-checked.

## Scope

Target public symbol: `sympy.geometry.point.Point.distance`.

The audited V1 source is `repo/sympy/geometry/point.py`. The function under
audit has no explicit loop; the only implicit iteration is over coordinate
pairs. The mini-K model represents that iteration with a recursive
specification function over coordinate lists.

## Intent Spec

I-001. `Point.distance` is intended to return Euclidean distance.

Evidence:

- Source: issue prompt.
- Quote: "distance calculation wrong".
- Obligation: the result is a Euclidean distance, not a truncated-coordinate
  distance.

I-002. Extra coordinates in a higher-dimensional point are in-domain and must
contribute to the Euclidean distance.

Evidence:

- Source: issue prompt.
- Quote: "`Point(2,0).distance(Point(1,0,2))` ... is being computed instead of
  `sqrt(5)`."
- Obligation: a missing coordinate in the shorter point contributes as zero.

I-003. The general contract applies to n-dimensional points.

Evidence:

- Source: `Point` class docstring.
- Quote: "A point in a n-dimensional Euclidean space."
- Obligation: the coordinate-wise formula must range over the ambient dimension
  needed to include all supplied coordinates.

I-004. Same-dimensional behavior is preserved.

Evidence:

- Source: public API compatibility and existing method examples.
- Quote: examples show `Point(1, 1).distance(Point(4, 5)) == 5` and
  `Point(x, y).distance(Point(0, 0)) == sqrt(x**2 + y**2)`.
- Obligation: when both arguments have the same length, the old zip formula and
  the zero-fill formula coincide.

## Public Evidence Ledger

E-001 | prompt | "`sqrt((2-1)**2 + (0-0)**2)` is being computed instead of
`sqrt(5)`" | Postcondition for the concrete 2D/3D example | encoded in
PO-002 and K claim `POINT-DISTANCE-REPORTED`.

E-002 | prompt | "The 3rd dimension is being ignored when the Points are zipped
together" | Root cause is truncating pair iteration | encoded in PO-001 by using
longest-coordinate iteration with zero fill.

E-003 | docs | "A point in a n-dimensional Euclidean space" | Domain includes
arbitrary finite coordinate lists | encoded in PO-001 and K claim
`POINT-DISTANCE-GENERAL`.

E-004 | docs/examples | same-dimensional distance examples | Frame condition for
same-dimensional points | encoded in PO-003.

E-005 | implementation | V1 uses `zip_longest(..., fillvalue=S.Zero)` in
`Point.distance` | Candidate transition shape, not independent intent |
checked against PO-001 through PO-003.

## Formal Spec English

FS-001. For coordinate lists `A` and `B`, `Point.distance` must return:

`sqrt(sum((coord(A, i) - coord(B, i))**2 for i in range(max(len(A), len(B)))))`

where `coord(L, i)` is `0` if `i` is outside `L`.

FS-002. The reported call `Point(2, 0).distance(Point(1, 0, 2))` must return
`sqrt(5)`.

FS-003. If `len(A) == len(B)`, FS-001 reduces to the previous same-dimensional
formula using ordinary `zip`; therefore same-dimensional public behavior is
preserved.

FS-004. The public method signature and return shape remain unchanged:
`distance(self, p)` still returns a SymPy expression involving `sqrt`.

## Adequacy Audit

FS-001 vs I-001/I-002/I-003: pass. It directly encodes Euclidean distance over
all supplied coordinates and zero-fills missing coordinates.

FS-002 vs I-002: pass. The concrete arithmetic is
`(2 - 1)**2 + (0 - 0)**2 + (0 - 2)**2 == 5`.

FS-003 vs I-004: pass. `zip_longest` with zero fill is extensionally identical
to `zip` when both lists have equal length.

FS-004 vs compatibility: pass. V1 changed only the internal iterator and import;
the method name, argument count, and result expression form are unchanged.

Adjacent zip-based methods such as `midpoint`, `dot`, and `taxicab_distance`
were reviewed as compatibility/context. The issue's explicit expected value is
Euclidean (`sqrt(5)`) and names `.distance`; no public evidence in the allowed
inputs requires changing those methods for this task.

## K Artifact Summary

Supporting formal core:

- `fvk/mini-python.k`: a minimal expression semantics for point coordinate
  lists and Euclidean distance.
- `fvk/point-distance-spec.k`: K claims for the general zero-fill contract and
  the reported concrete example.

Exact commands to machine-check later, not run in this session:

```sh
kompile fvk/mini-python.k --backend haskell
kast --backend haskell fvk/point-distance-spec.k
kprove fvk/point-distance-spec.k
```

Expected machine-check result if the fragment and claims are accepted:
`kprove` returns `#Top`.
