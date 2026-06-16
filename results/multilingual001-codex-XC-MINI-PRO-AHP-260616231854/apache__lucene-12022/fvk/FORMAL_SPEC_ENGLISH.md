# Formal Spec English

Status: English paraphrase of the K claims, constructed but not machine-checked.

## Claim `RESOLVE-POINT`

For any decoded triangle whose three encoded vertices are the same point, calling `resolveTriangleType` returns with the same coordinates and edge flags and sets `type` to `POINT`.

## Claim `RESOLVE-AEQB-LINE`

For any decoded triangle where `A` and `B` are the same encoded point and `C` is distinct, calling `resolveTriangleType` returns a canonical line `A-C-A`, sets `type` to `LINE`, and sets the line edge flag `ab` to the old `bc` value. This is the core issue obligation: the line flag comes from the non-collapsed `B-C` segment.

## Claim `RESOLVE-AEQC-LINE`

For any decoded triangle where `A` and `C` are the same encoded point while `A` and `B` are distinct, calling `resolveTriangleType` sets `type` to `LINE` without changing the coordinates or `ab`; the represented line remains `A-B-A`.

## Claim `RESOLVE-BEQC-LINE`

For any decoded triangle where `B` and `C` are the same encoded point while neither earlier degenerate branch applies, calling `resolveTriangleType` rewrites `C` to `A`, sets `type` to `LINE`, and leaves `ab` as the old `ab`; the represented line remains `A-B-A`.

## Claim `RESOLVE-TRIANGLE`

For any decoded triangle whose three encoded vertices are pairwise distinct, calling `resolveTriangleType` returns with coordinates and edge flags unchanged and sets `type` to `TRIANGLE`.

## Query Bridge Obligation

For decoded `LINE` values, the shape `CONTAINS` query path passes only `ab` to `withinLine`. Therefore satisfying the `RESOLVE-AEQB-LINE` claim is sufficient for the reported false positive mechanism: the query will see the retained `B-C` edge's polygon-membership flag instead of the collapsed `A-B` flag.
