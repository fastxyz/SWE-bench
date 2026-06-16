# Formal Spec in English

This file paraphrases each nontrivial K claim in
`fvk/annotation-coordinate-spec.k`.

## `annotation-base-xy-copy-y`

If an annotation stores `xy` from a mutable coordinate array containing
`(x, y)`, and the caller later mutates the array's y component to `y2`, the
heap array changes to `(x, y2)` but the stored annotation coordinate remains
`(x, y)`.

## `annotation-base-xy-copy-x`

If an annotation stores `xy` from a mutable coordinate array containing
`(x, y)`, and the caller later mutates the array's x component to `x2`, the
heap array changes to `(x2, y)` but the stored annotation coordinate remains
`(x, y)`.

## `offsetfrom-ref-copy-y`

If `OffsetFrom` stores `ref_coord` from a mutable coordinate array containing
`(x, y)`, and the caller later mutates the array's y component, the stored
reference coordinate remains `(x, y)`.

## `annotationbbox-explicit-xybox-copy-y`

If `AnnotationBbox` stores an explicitly supplied `xybox` from a mutable
coordinate array containing `(x, y)`, and the caller later mutates the array's y
component, the stored box coordinate remains `(x, y)`.

## `annotationbbox-default-xybox-uses-copied-xy`

If `AnnotationBbox` receives `xy` from a mutable coordinate array and `xybox` is
omitted, it first stores the copied `xy` coordinate and then sets `xybox` from
that copied value. Later mutation of the caller's original `xy` array changes
the heap object but neither `xy` nor `xybox`.

## `connectionpatch-endpoints-copy-y`

If `ConnectionPatch` stores endpoints `xyA` and `xyB` from two mutable
coordinate arrays and the caller later mutates those arrays' y components, the
caller arrays change but `xy1` and `xy2` remain the construction-time endpoint
tuples.

## Side Conditions

The symbolic array identifiers are valid and distinct where two arrays are used.
The coordinate pair contains exactly two scalar coordinate values.
