# FVK Specification

Status: constructed, not machine-checked.

## Scope

The verified unit is the constructor-time coordinate storage behavior touched by
V1:

- `_AnnotationBase.__init__` in `repo/lib/matplotlib/text.py`
- `OffsetFrom.__init__` in `repo/lib/matplotlib/text.py`
- `AnnotationBbox.__init__` in `repo/lib/matplotlib/offsetbox.py`
- `ConnectionPatch.__init__` in `repo/lib/matplotlib/patches.py`

The model intentionally abstracts away rendering, unit conversion, transforms,
and clipping. Those paths consume `self.xy`, `_ref_coord`, `xybox`, `xy1`, or
`xy2`; the issue is whether those stored values are aliases of caller-owned
mutable arrays.

## Domain

Inputs are point-like iterables containing exactly two scalar coordinate values,
matching the documented `(float, float)` contract. Scalar values include numeric
and unit-convertible scalar coordinate objects. Containers nested inside the
coordinate elements themselves are outside this domain.

## Public Intent Ledger

The detailed ledger is in `fvk/PUBLIC_EVIDENCE_LEDGER.md`. The critical entries
are:

- E1/E2: after `ax.annotate(..., xy=xy_0, arrowprops=...)`, later
  `xy_0[1] = 3` must not change the stored endpoint.
- E3: copying the array is the intended repair shape.
- E4: `OffsetFrom` is a public hint for the same class of bug.
- E6/E9: stored coordinates have public tuple-like behavior, so the copy should
  not globally turn these attributes into NumPy arrays.
- E7/E8: `AnnotationBbox.xybox` and `ConnectionPatch.xy1`/`xy2` are also
  documented as coordinate tuples and read later.

## Formal Model

`fvk/mini-python.k` models only what is needed for this property:

- a mutable caller-owned coordinate pair in a heap, represented as
  `arr(A) |-> pair(X, Y)`;
- storage commands that copy heap values into independent tuple cells;
- mutation commands that update only the heap object.

`fvk/annotation-coordinate-spec.k` contains K reachability claims for:

- `_AnnotationBase.xy` copying before later x or y mutation;
- `OffsetFrom._ref_coord` copying before later mutation;
- explicit `AnnotationBbox.xybox` copying;
- omitted `AnnotationBbox.xybox` defaulting to copied `self.xy`;
- `ConnectionPatch.xy1` and `xy2` copying before endpoint arrays are mutated.

## Postconditions

For every in-domain coordinate pair `(x, y)` supplied through a mutable array:

- the stored coordinate equals `(x, y)` immediately after construction;
- after any later mutation of the original array's first or second component,
  the stored coordinate still equals `(x, y)`;
- the caller-owned array may change, but the stored coordinate cells are framed
  and unchanged.

## Frame Conditions

- Function signatures and accepted coordinate forms are unchanged.
- Public coordinate attributes remain indexable and unpackable.
- Tuple equality such as `ann.xy == (x, y)` remains valid.
- Explicit reassignment of public attributes after construction remains outside
  this proof and is not changed by V1.

## Candidate Verdict

The V1 source changes satisfy this specification. No additional production-code
edit is justified by the FVK obligations.
